# -----------------------------------------------------------------------------
# examples/aws-end-to-end
#
# Golden standard end-to-end Terraform reference for Zscaler Zero Trust Gateway
# on Amazon Web Services (AWS).
#
# Steps performed in a single `terraform apply`:
#   1. Authenticates to Zscaler OneAPI (Zidentity) via OAuth2.
#   2. Provisions the managed AWS ZTGW via the Zscaler Public Connector API.
#   3. Polls until the ZTGW is HEALTHY and captures the generated Gateway Load
#      Balancer (GWLB) Endpoint Service Name.
#   4. Deploys an AWS VPC Endpoint (type GatewayLoadBalancer) into the customer VPC.
#   5. Updates the customer's workload route tables to direct egress traffic
#      into the ZTGW endpoint.
# -----------------------------------------------------------------------------

provider "ztc" {
  client_id     = var.client_id
  client_secret = var.client_secret
  vanity_domain = var.vanity_domain
  zscaler_cloud = var.cloud
}

provider "aws" {
  region = var.aws_region
}

locals {
  endpoint_service_name = var.deploy_ztgw ? module.ztgw_gateway[0].endpoint_service_name : var.endpoint_service_name
}

# --- 1. Provision Zscaler Managed ZTGW in AWS (OneAPI) -----------------------
module "ztgw_gateway" {
  count  = var.deploy_ztgw ? 1 : 0
  source = "../../../modules/terraform-ztgw-gateway-aws"

  client_id          = var.client_id
  client_secret      = var.client_secret
  vanity_domain      = var.vanity_domain
  cloud              = var.cloud
  login_domain       = var.login_domain
  gateway_name       = var.gateway_name
  platform           = "AWS"
  region             = var.aws_region
  availability_zones = var.availability_zones
  location_name      = var.location_name != null ? var.location_name : "Unified-AWS-${var.aws_region}"

  # Whitelist the customer's AWS account on the GWLB Endpoint Service:
  allowlist_projects    = [var.customer_aws_account_id]
  insecure_skip_verify  = var.insecure_skip_verify
  auto_activate_pending = var.auto_activate_pending
}

# --- 2. Attach Customer VPC to ZTGW via Gateway Load Balancer Endpoint --------
module "gwlb_consumer" {
  count  = var.deploy_consumer ? 1 : 0
  source = "../../../modules/terraform-ztgw-gwlb-consumer-aws"

  vpc_id                   = var.customer_vpc_id
  endpoint_subnet_ids      = var.endpoint_subnet_ids
  workload_route_table_ids = var.workload_route_table_ids
  intercept_cidr_block     = var.intercept_cidr_block
  deploy_key               = var.deploy_key

  # Seamless handoff: output of module.ztgw_gateway or input endpoint service name
  endpoint_service_name     = local.endpoint_service_name
  overwrite_existing_routes = var.overwrite_existing_routes
}
