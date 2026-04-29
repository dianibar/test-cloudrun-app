resource "google_compute_region_network_endpoint_group" "app" {
  name                  = "test-cloudrun-app-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project               = var.project_id

  cloud_run {
    service = google_cloud_run_v2_service.app.name
  }
}

resource "google_compute_backend_service" "app" {
  name    = "test-cloudrun-app-backend"
  project = var.project_id

  backend {
    group = google_compute_region_network_endpoint_group.app.id
  }

  iap {
    enabled              = true
    oauth2_client_id     = "TODO: set your IAP OAuth2 client ID"
    oauth2_client_secret = "TODO: set your IAP OAuth2 client secret"
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