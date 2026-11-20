# ==============================================================================
# examples/aws/consumer-brownfield
#
# Dedicated reference for Application, Cloud, and DevOps teams connecting an
# EXISTING customer AWS VPC to an already-provisioned ZTGW Endpoint Service.
#
# Zero Zscaler OneAPI credentials required here.
# Only the Endpoint Service name supplied by InfoSec is needed.
# ==============================================================================

provider "aws" {
  region = var.aws_region
}

module "gwlb_consumer" {
  source = "../../../modules/terraform-ztgw-gwlb-consumer-aws"

  vpc_id                   = var.customer_vpc_id
  endpoint_subnet_ids      = var.endpoint_subnet_ids
  endpoint_service_name    = var.endpoint_service_name
  workload_route_table_ids = var.workload_route_table_ids
  intercept_cidr_block     = var.intercept_cidr_block
  deploy_key               = var.deploy_key
  overwrite_existing_routes = var.overwrite_existing_routes
}
