terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "TODO: set your terraform state bucket"
    prefix = "test-cloudrun-app"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudkms.googleapis.com",
    "binaryauthorization.googleapis.com",
    "artifactregistry.googleapis.com",
    "vpcaccess.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}