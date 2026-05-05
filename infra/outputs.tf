output "service_url" {
  description = "Cloud Run service URL (internal — access via IAP load balancer)"
  value       = google_cloud_run_v2_service.app.uri
}

output "service_account_email" {
  description = "Service account email for the Cloud Run service"
  value       = google_service_account.app.email
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL for pushing images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/test-cloudrun-app"
}

output "wif_provider" {
  description = "Workload Identity Federation provider resource name — copy to GitHub Actions variable WIF_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "deploy_service_account" {
  description = "Service account email for GitHub Actions to impersonate — copy to GitHub Actions variable DEPLOY_SERVICE_ACCOUNT"
  value       = google_service_account.app.email
}

output "load_balancer_ip" {
  description = "External IP of the IAP-protected load balancer"
  value       = google_compute_global_forwarding_rule.default.ip_address
}