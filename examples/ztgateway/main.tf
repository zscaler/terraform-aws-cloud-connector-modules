################################################################################
# Generate a unique random string for resource name assignment and key pair
################################################################################
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}


################################################################################
# Map default tags with values to be assigned to all tagged resources
################################################################################
locals {
  global_tags = {
    Owner                                                                                 = var.owner_tag
    ManagedBy                                                                             = "terraform"
    Vendor                                                                                = "Zscaler"
    "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}" = "shared"
  }
}

################################################################################
# 1. Create/reference all network infrastructure resource dependencies for all 
#    child modules (vpc, igw, nat gateway, subnets, route tables)
################################################################################
module "network" {
  source            = "../../modules/terraform-zscc-network-aws"
  name_prefix       = var.name_prefix
  resource_tag      = random_string.suffix.result
  global_tags       = local.global_tags
  az_count          = var.az_count
  az_ids            = var.az_ids
  vpc_cidr          = var.vpc_cidr
  cc_subnets        = var.endpoint_subnets
  gwlb_enabled      = true
  gwlb_endpoint_ids = module.gwlb_endpoint.gwlbe
  exclude_igw       = var.exclude_igw
  exclude_ngw       = var.exclude_ngw

  #bring-your-own variables
  byo_vpc                = var.byo_vpc
  byo_vpc_id             = var.byo_vpc_id
  byo_subnets            = var.byo_subnets
  byo_subnet_ids         = var.byo_subnet_ids
  cc_route_table_enabled = var.zs_route_table_enabled
}

################################################################################
# 2. Create 1x GWLB Endpoint per Zscaler subnet/availability zone
################################################################################
module "gwlb_endpoint" {
  source                    = "../../modules/terraform-zscc-gwlbendpoint-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.cc_subnet_ids
  byo_endpoint_service_name = var.byo_endpoint_service_name
}
