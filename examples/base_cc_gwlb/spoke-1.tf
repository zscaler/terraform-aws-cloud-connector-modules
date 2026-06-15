################################################################################
# 1. Create/reference all network infrastructure resource dependencies for all 
#    child modules (vpc, igw, nat gateway, subnets, route tables)
################################################################################
module "spoke_1_network" {
  source            = "../../modules/terraform-zscc-spoke-network-aws"
  name_prefix       = var.name_prefix
  resource_tag      = random_string.suffix.result
  global_tags       = local.global_tags
  workloads_enabled = true
  az_count          = var.az_count
  vpc_cidr          = var.vpc_cidr
  public_subnets    = var.public_subnets
  workloads_subnets = var.workloads_subnets
  cc_subnets        = var.cc_subnets
  gwlb_enabled      = var.gwlb_enabled
  gwlb_endpoint_ids = module.spoke_1_gwlb_endpoint.gwlbe
}


################################################################################
# 2. Create Bastion Host for workload and CC SSH jump access
################################################################################
module "spoke_1_bastion" {
  source                    = "../../modules/terraform-zscc-bastion-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = module.spoke_1_network.vpc_id
  public_subnet             = module.spoke_1_network.public_subnet_ids[0]
  instance_key              = aws_key_pair.deployer.key_name
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
  bastion_iam_role_name = "spoke-1-bastion-iam-role-${random_string.suffix.result}"
}

################################################################################
# 3. Create Workload Hosts to test traffic connectivity through CC
################################################################################
module "spoke_1_workload" {
  workload_count = var.workload_count
  source         = "../../modules/terraform-zscc-workload-aws"
  name_prefix    = "${var.name_prefix}-workload"
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  vpc_id         = module.spoke_1_network.vpc_id
  subnet_id      = module.spoke_1_network.workload_subnet_ids
  instance_key   = aws_key_pair.deployer.key_name
  workload_private_ip = var.workload_private_ip
  workload_iam_role_name = "spoke-1-iam-role-${random_string.suffix.result}"
}

################################################################################
# 8. Create a VPC Endpoint Service associated with GWLB and 1x GWLB Endpoint 
#    per Cloud Connector subnet/availability zone.
################################################################################
module "spoke_1_gwlb_endpoint" {
  source              = "../../modules/terraform-zscc-spoke-gwlbendpoint-aws"
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  global_tags         = local.global_tags
  vpc_id              = module.spoke_1_network.vpc_id
  subnet_ids          = module.spoke_1_network.workload_subnet_ids
  gwlb_arn            = module.gwlb.gwlb_arn
  acceptance_required = var.acceptance_required
  allowed_principals  = var.allowed_principals
  endpoint_service_name = module.gwlb_endpoint.vpce_service_name
}
