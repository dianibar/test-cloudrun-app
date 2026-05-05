resource "google_compute_region_network_endpoint_group" "app" {
  name                  = "test-cloudrun-app-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project               = var.project_id

  cloud_run {
    service = google_cloud_run_v2_service.app.name
  }
}

# IAP OAuth2 credentials — stored in Secret Manager, never in code.
# Before running terraform apply, add the values:
#   gcloud secrets versions add test-cloudrun-app-iap-oauth2-client-id     --data-file=- <<< "your-client-id"
#   gcloud secrets versions add test-cloudrun-app-iap-oauth2-client-secret  --data-file=- <<< "your-client-secret"
# See infra/SETUP.md for instructions on creating the OAuth2 credentials.

resource "google_secret_manager_secret" "iap_client_id" {
  secret_id = "test-cloudrun-app-iap-oauth2-client-id"
  project   = var.project_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "iap_client_secret" {
  secret_id = "test-cloudrun-app-iap-oauth2-client-secret"
  project   = var.project_id
  replication {
    auto {}
  }
}

data "google_secret_manager_secret_version" "iap_client_id" {
  secret  = google_secret_manager_secret.iap_client_id.secret_id
  project = var.project_id
  depends_on = [google_secret_manager_secret.iap_client_id]
}

data "google_secret_manager_secret_version" "iap_client_secret" {
  secret  = google_secret_manager_secret.iap_client_secret.secret_id
  project = var.project_id
  depends_on = [google_secret_manager_secret.iap_client_secret]
}

resource "google_compute_backend_service" "app" {
  name    = "test-cloudrun-app-backend"
  project = var.project_id

  backend {
    group = google_compute_region_network_endpoint_group.app.id
  }

  iap {
    enabled              = true
    oauth2_client_id     = data.google_secret_manager_secret_version.iap_client_id.secret_data
    oauth2_client_secret = data.google_secret_manager_secret_version.iap_client_secret.secret_data
  }

  log_config {
    enable = true
  }
}

resource "google_compute_managed_ssl_certificate" "app" {
  name    = "test-cloudrun-app-cert"
  project = var.project_id

  managed {
    domains = ["TODO: set your domain e.g. test-cloudrun-app.example.com"]
  }
}

resource "google_compute_url_map" "app" {
  name            = "test-cloudrun-app-urlmap"
  project         = var.project_id
  default_service = google_compute_backend_service.app.id
}

resource "google_compute_target_https_proxy" "app" {
  name             = "test-cloudrun-app-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.app.id
  ssl_certificates = [google_compute_managed_ssl_certificate.app.id]
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "test-cloudrun-app-forwarding-rule"
  project    = var.project_id
  target     = google_compute_target_https_proxy.app.id
  port_range = "443"
  ip_protocol = "TCP"
}

# IAP access — add users/groups who should be able to reach the service
resource "google_iap_web_backend_service_iam_member" "allowed" {
  for_each = toset(var.iap_allowed_members)

  project             = var.project_id
  web_backend_service = google_compute_backend_service.app.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = each.value
}