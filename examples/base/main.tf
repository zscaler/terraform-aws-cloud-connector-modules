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
# The following lines generates a new SSH key pair and stores the PEM file 
# locally. The public key output is used as the instance_key passed variable 
# to the ec2 modules for admin_ssh_key public_key authentication.
# This is not recommended for production deployments. Please consider modifying 
# to pass your own custom public key file located in a secure location.   
################################################################################
resource "tls_private_key" "key" {
  algorithm = var.tls_key_algorithm
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.name_prefix}-key-${random_string.suffix.result}"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "../${var.name_prefix}-key-${random_string.suffix.result}.pem"
  file_permission = "0600"
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
  workloads_enabled = true
  az_count          = var.az_count
  vpc_cidr          = var.vpc_cidr
  public_subnets    = var.public_subnets
  workloads_subnets = var.workloads_subnets
  base_only         = true
}


################################################################################
# 2. Create Bastion Host for workload and CC SSH jump access
################################################################################
module "bastion" {
  source                    = "../../modules/terraform-zscc-bastion-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = module.network.vpc_id
  public_subnet             = module.network.public_subnet_ids[0]
  instance_key              = aws_key_pair.deployer.key_name
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
}


################################################################################
# 3. Create Workload Hosts to test traffic connectivity through CC
################################################################################
module "workload" {
  workload_count = var.workload_count
  source         = "../../modules/terraform-zscc-workload-aws"
  name_prefix    = "${var.name_prefix}-workload"
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  vpc_id         = module.network.vpc_id
  subnet_id      = module.network.workload_subnet_ids
  instance_key   = aws_key_pair.deployer.key_name
}
