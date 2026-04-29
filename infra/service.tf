resource "google_cloud_run_v2_service" "app" {
  name     = "test-cloudrun-app"
  location = var.region
  project  = var.project_id

  # Internal traffic only — all external access goes through the IAP load balancer
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    service_account       = google_service_account.app.email

    # CMEK encryption — must be set at template level for Cloud Run v2
    encryption_key = google_kms_crypto_key.app.id

    # Direct VPC egress — no public outbound traffic
    vpc_access {
      network_interfaces {
        network    = var.vpc_network
        subnetwork = var.vpc_subnetwork
      }
      egress = "PRIVATE_RANGES_ONLY"
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/test-cloudrun-app/test-cloudrun-app:latest"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      env {
        name  = "PORT"
        value = "TODO: set value for PORT"
      }
      env {
        name  = "GCP_PROJECT_ID"
        value = "TODO: set value for GCP_PROJECT_ID"
      }
      env {
        name  = "GCS_BUCKET"
        value = "TODO: set value for GCS_BUCKET"
      }
      env {
        name  = "DATABASE_URL"
        value = "TODO: set value for DATABASE_URL"
      }

      env {
        name = "API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.api_key.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secret_key.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "STRIPE_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.stripe_token.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_kms_crypto_key_iam_member.run_agent,
  ]
}
