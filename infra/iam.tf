resource "google_service_account" "app" {
  account_id   = "test-cloudrun-app-run-sa"
  display_name = "test-cloudrun-app Cloud Run service account"
  project      = var.project_id
}

# Base roles every Cloud Run service needs
resource "google_project_iam_member" "base_roles" {
  for_each = toset([
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/cloudtrace.agent",
    "roles/monitoring.metricWriter",
    "roles/bigquery.jobUser",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Only the IAP service account may invoke the Cloud Run service
resource "google_cloud_run_v2_service_iam_member" "iap_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
}