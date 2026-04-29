# Direct VPC egress is configured in service.tf via vpc_access.network_interfaces.
# The variables below point to the VPC network and subnetwork to use.
# Update var.vpc_network and var.vpc_subnetwork in your tfvars file.
#
# If Direct VPC egress is not available in your region, replace the vpc_access block
# in service.tf with a VPC connector:
#
# resource "google_vpc_access_connector" "app" {
#   name          = "test-cloudrun-app-connector"
#   region        = var.region
#   project       = var.project_id
#   network       = var.vpc_network
#   ip_cidr_range = "10.8.0.0/28"   # must be an unused /28 in your VPC
#   min_instances = 2
#   max_instances = 10
# }
#
# Then in service.tf vpc_access block use:
#   connector = google_vpc_access_connector.app.id
#   egress    = "PRIVATE_RANGES_ONLY"