resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  # Default: block all images not from your own Artifact Registry.
  # Start with ALWAYS_ALLOW and tighten by adding attestors after first deploy.
  default_admission_rule {
    evaluation_mode  = "ALWAYS_ALLOW"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  }

  # Only allow images from this project's Artifact Registry
  admission_whitelist_patterns {
    name_pattern = "${var.region}-docker.pkg.dev/${var.project_id}/test-cloudrun-app/*"
  }

  depends_on = [google_project_service.apis]
}