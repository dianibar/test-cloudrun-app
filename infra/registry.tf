resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = "test-cloudrun-app"
  format        = "DOCKER"
  project       = var.project_id

  cleanup_policies {
    id     = "keep-10-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  depends_on = [google_project_service.apis]
}

# Cloud Run service account can pull images
resource "google_artifact_registry_repository_iam_member" "run_reader" {
  location   = var.region
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.app.email}"
  project    = var.project_id
}

# GitHub Actions service account can push images
resource "google_artifact_registry_repository_iam_member" "cicd_writer" {
  location   = var.region
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.app.email}"
  project    = var.project_id
}