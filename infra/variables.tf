variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run and related resources"
  type        = string
  default     = "us-central1"
}

variable "vpc_network" {
  description = "VPC network name for Direct VPC egress"
  type        = string
  default     = "default"
}

variable "vpc_subnetwork" {
  description = "VPC subnetwork name for Direct VPC egress"
  type        = string
  default     = "default"
}

variable "iap_allowed_members" {
  description = "List of IAM members allowed to access the service via IAP (e.g. user:foo@example.com, group:devs@example.com)"
  type        = list(string)
  default     = []
}

variable "github_org" {
  description = "GitHub organization or user that owns the service repository"
  type        = string
  default     = "dianibar"
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix)"
  type        = string
  default     = "test-cloudrun-app"
}