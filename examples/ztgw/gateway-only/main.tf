# ==============================================================================
# examples/aws/gateway-only
#
# Dedicated reference for InfoSec and Platform teams provisioning ONLY the
# Zscaler Managed Zero Trust Gateway (ZTGW) on AWS via Zscaler OneAPI.
#
# This module creates the Cloud Connector cluster and AWS Gateway Load Balancer,
# registers with the Zscaler Cloud, and outputs the Endpoint Service name.
# It does NOT touch customer VPCs, subnets, or route tables.
# ==============================================================================

provider "ztc" {
  client_id     = var.client_id
  client_secret = var.client_secret
  vanity_domain = var.vanity_domain
  zscaler_cloud = var.cloud
}

module "ztgw_gateway" {
  source = "../../../modules/terraform-ztgw-gateway-aws"

  client_id             = var.client_id
  client_secret         = var.client_secret
  vanity_domain         = var.vanity_domain
  cloud                 = var.cloud
  login_domain          = var.login_domain
  gateway_name          = var.gateway_name
  platform              = "AWS"
  region                = var.aws_region
  availability_zones    = var.availability_zones
  location_name         = var.location_name != null ? var.location_name : "Unified-AWS-${var.aws_region}"
  allowlist_projects    = var.customer_aws_account_ids
  insecure_skip_verify   = var.insecure_skip_verify
  auto_activate_pending = var.auto_activate_pending
}
