# GCS buckets — auto-created for every env var whose name contains "BUCKET".
# The service account is granted objectAdmin on each bucket.
# Bucket names follow: <project_id>-<service_name>-<env_var_kebab_case>

resource "google_storage_bucket" "gcs_bucket" {
  name     = "${var.project_id}-test-cloudrun-app-gcs-bucket"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_member" "gcs_bucket_writer" {
  bucket = google_storage_bucket.gcs_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.app.email}"
}
