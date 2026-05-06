resource "google_kms_key_ring" "app" {
  name     = "test-cloudrun-app-keyring"
  location = var.region
  project  = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_kms_crypto_key" "app" {
  name            = "test-cloudrun-app-key"
  key_ring        = google_kms_key_ring.app.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# Grant Cloud Run service agent permission to use the key
resource "google_kms_crypto_key_iam_member" "run_agent" {
  crypto_key_id = google_kms_crypto_key.app.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
}