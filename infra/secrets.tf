resource "google_secret_manager_secret" "api_key" {
  secret_id = "test-cloudrun-app-api-key"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "api_key_placeholder" {
  secret      = google_secret_manager_secret.api_key.id
  secret_data = "placeholder"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret" "secret_key" {
  secret_id = "test-cloudrun-app-secret-key"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "secret_key_placeholder" {
  secret      = google_secret_manager_secret.secret_key.id
  secret_data = "placeholder"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret" "stripe_token" {
  secret_id = "test-cloudrun-app-stripe-token"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "stripe_token_placeholder" {
  secret      = google_secret_manager_secret.stripe_token.id
  secret_data = "placeholder"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

