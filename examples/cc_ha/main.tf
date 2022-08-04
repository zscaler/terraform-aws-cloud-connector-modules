# Generate a unique random string for resource name assignment and key pair
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

# Map default tags with values to be assigned to all tagged resources
locals {
  global_tags = {
    Owner                                                                                 = var.owner_tag
    ManagedBy                                                                             = "terraform"
    Vendor                                                                                = "Zscaler"
    "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}" = "shared"
  }
}

############################################################################################################################
#### The following lines generates a new SSH key pair and stores the PEM file locally. The public key output is used    ####
#### as the instance_key passed variable to the ec2 modules for admin_ssh_key public_key authentication                 ####
#### This is not recommended for production deployments. Please consider modifying to pass your own custom              ####
#### public key file located in a secure location                                                                       ####
############################################################################################################################
# private key for login
resource "tls_private_key" "key" {
  algorithm = var.tls_key_algorithm
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.name_prefix}-key-${random_string.suffix.result}"
  public_key = tls_private_key.key.public_key_openssh

  provisioner "local-exec" {
    command = <<EOF
      echo "${tls_private_key.key.private_key_pem}" > ../${var.name_prefix}-key-${random_string.suffix.result}.pem
      chmod 0600 ../${var.name_prefix}-key-${random_string.suffix.result}.pem
EOF
  }
}


# 1. Create/reference all network infrastructure resource dependencies for all child modules (vpc, igw, nat gateway, subnets, route tables)
module "network" {
  source            = "../../modules/terraform-zscc-network-aws"
  name_prefix       = var.name_prefix
  resource_tag      = random_string.suffix.result
  global_tags       = local.global_tags
  byo_vpc           = var.byo_vpc
  byo_vpc_id        = var.byo_vpc_id
  byo_subnets       = var.byo_subnets
  byo_subnet_ids    = var.byo_subnet_ids
  byo_igw           = var.byo_igw
  byo_igw_id        = var.byo_igw_id
  zpa_enabled       = var.zpa_enabled
  workloads_enabled = var.workloads_enabled
  gwlb_enabled      = var.gwlb_enabled
  cc_service_enis   = module.cc-vm.service_eni_1
  az_count          = var.az_count
  vpc_cidr          = var.vpc_cidr
}


# 2. Create X CC VMs per cc_count which will span equally across designated availability zones per az_count
#    E.g. cc_count set to 4 and az_count set to 2 or byo_subnet_ids configured for 2 will create 2x CCs in AZ subnet 1 and 2x CCs in AZ subnet 2

## Create the user_data file
locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
SECRET_NAME=${var.secret_name}
HTTP_PROBE_PORT=${var.http_probe_port}
USERDATA
}

resource "local_file" "user-data-file" {
  content  = local.userdata
  filename = "../user_data"
}

module "cc-vm" {
  source                    = "../../modules/terraform-zscc-ccvm-aws"
  cc_count                  = var.cc_count
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = module.network.vpc_id
  mgmt_subnet_id            = module.network.cc_subnet_ids
  service_subnet_id         = module.network.cc_subnet_ids
  instance_key              = aws_key_pair.deployer.key_name
  user_data                 = local.userdata
  ccvm_instance_type        = var.ccvm_instance_type
  cc_instance_size          = var.cc_instance_size
  iam_instance_profile      = module.cc-iam.iam_instance_profile_id
  mgmt_security_group_id    = module.cc-sg.mgmt_security_group_id
  service_security_group_id = module.cc-sg.service_security_group_id

}


# 3. Create IAM Policy, Roles, and Instance Profiles to be assigned to CC appliances. Default behavior will create 1 of each resource per CC VM. Set variable reuse_iam to true
#    if you would like a single IAM profile created and assigned to ALL Cloud Connectors
module "cc-iam" {
  source              = "../../modules/terraform-zscc-iam-aws"
  iam_count           = var.reuse_iam == false ? var.cc_count : 1
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  global_tags         = local.global_tags
  cc_callhome_enabled = var.cc_callhome_enabled

  byo_iam = var.byo_iam
  # optional inputs. only required if byo_iam set to true
  byo_iam_instance_profile_id = var.byo_iam_instance_profile_id
  # optional inputs. only required if byo_iam set to true
}


# 4. Create Security Group and rules to be assigned to CC mgmt and and service interface(s). Default behavior will create 1 of each resource per CC VM. Set variable reuse_security_group
#    to true if you would like a single security group created and assigned to ALL Cloud Connectors
module "cc-sg" {
  source       = "../../modules/terraform-zscc-sg-aws"
  sg_count     = var.reuse_security_group == false ? var.cc_count : 1
  name_prefix  = var.name_prefix
  resource_tag = random_string.suffix.result
  global_tags  = local.global_tags
  vpc_id       = module.network.vpc_id

  byo_security_group = var.byo_security_group
  # optional inputs. only required if byo_security_group set to true
  byo_mgmt_security_group_id    = var.byo_mgmt_security_group_id
  byo_service_security_group_id = var.byo_service_security_group_id
  # optional inputs. only required if byo_security_group set to true
}


# 5. Create Lambda for HA between pair of Cloud Connectors. If deploying more than a single pair of Cloud Connectors,
#    you will need to: 
#    1. copy this module reference
#    2. replace the values for cc_vm1_id, cc_vm2_id and potentially cc_vm1_snid and cc_vm2_snid
#    3. define a new list route table IDs for cc_vm1_rte_list/cc_vm2_rte_list inline or by creating new variables
#       e.g workload_route_table_ids_to_cc_3, etc.
#
#    **** Note - Lambda is not required for single or non-redundant deployments. You will need to at least specify an 
#                existing VPC ID though for workload route table selection logic to work

module "cc-lambda" {
  count           = var.byo_vpc == true ? 1 : 0
  source          = "../../modules/terraform-zscc-lambda-aws"
  name_prefix     = var.name_prefix
  resource_tag    = random_string.suffix.result
  global_tags     = local.global_tags
  vpc_id          = module.network.vpc_id
  cc_vm1_id       = module.cc-vm.id[0]
  cc_vm2_id       = module.cc-vm.id[1]
  cc_subnet_ids   = module.network.cc_subnet_ids
  cc_vm1_rte_list = var.workload_route_table_ids_to_cc_1
  cc_vm2_rte_list = var.workload_route_table_ids_to_cc_2
  http_probe_port = var.http_probe_port
}



# 6. Optional Route53 for ZPA
#    Create Route 53 Resolver Rules and Endpoints for utilization with DNS redirection to facilitate Cloud Connector ZPA service
module "route53" {
  count          = var.zpa_enabled == true ? 1 : 0
  source         = "../../modules/terraform-zscc-route53-aws"
  name_prefix    = var.name_prefix
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  vpc_id         = module.network.vpc_id
  r53_subnet_ids = module.network.route53_subnet_ids
  domain_names   = var.domain_names
  target_address = var.target_address
}