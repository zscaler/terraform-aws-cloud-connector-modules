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
  zpa_enabled       = var.zpa_enabled
  workloads_enabled = var.workloads_enabled
  gwlb_enabled      = var.gwlb_enabled
  cc_service_enis   = module.cc_vm.service_eni_1
  az_count          = var.az_count
  vpc_cidr          = var.vpc_cidr
  public_subnets    = var.public_subnets
  cc_subnets        = var.cc_subnets
  route53_subnets   = var.route53_subnets
  #bring-your-own variables
  byo_vpc        = var.byo_vpc
  byo_vpc_id     = var.byo_vpc_id
  byo_subnets    = var.byo_subnets
  byo_subnet_ids = var.byo_subnet_ids
  byo_igw        = var.byo_igw
  byo_igw_id     = var.byo_igw_id
  byo_ngw        = var.byo_ngw
  byo_ngw_ids    = var.byo_ngw_ids
}


################################################################################
# 2. Create specified number CC VMs per cc_count which will span equally across 
#    designated availability zones per az_count. E.g. cc_count set to 4 and 
#    az_count set to 2 will create 2x CCs in AZ1 and 2x CCs in AZ2
################################################################################
# Create the user_data file with necessary bootstrap variables for Cloud Connector registration
locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
SECRET_NAME=${var.secret_name}
HTTP_PROBE_PORT=${var.http_probe_port}
USERDATA
}

# Write the file to local filesystem for storage/reference
resource "local_file" "user_data_file" {
  content  = local.userdata
  filename = "../user_data"
}

################################################################################
# Locate Latest CC AMI by product code
################################################################################
data "aws_ami" "cloudconnector" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["2l8tfysndbav4tv2nfjwak3cu"]
  }

  owners = ["aws-marketplace"]
}

# Create specified number of CC appliances
module "cc_vm" {
  source                    = "../../modules/terraform-zscc-ccvm-aws"
  cc_count                  = var.cc_count
  ami_id                    = contains(var.ami_id, "") ? [data.aws_ami.cloudconnector.id] : var.ami_id
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  mgmt_subnet_id            = module.network.cc_subnet_ids
  service_subnet_id         = module.network.cc_subnet_ids
  instance_key              = aws_key_pair.deployer.key_name
  user_data                 = local.userdata
  ccvm_instance_type        = var.ccvm_instance_type
  cc_instance_size          = var.cc_instance_size
  iam_instance_profile      = module.cc_iam.iam_instance_profile_id
  mgmt_security_group_id    = module.cc_sg.mgmt_security_group_id
  service_security_group_id = module.cc_sg.service_security_group_id

  depends_on = [
    local_file.user_data_file,
    null_resource.cc_error_checker,
  ]
}


################################################################################
# 3. Create IAM Policy, Roles, and Instance Profiles to be assigned to CC. 
#    Default behavior will create 1 of each IAM resource per CC VM. Set variable 
#    "reuse_iam" to true if you would like a single IAM profile created and 
#    assigned to ALL Cloud Connectors instead.
################################################################################
module "cc_iam" {
  source              = "../../modules/terraform-zscc-iam-aws"
  iam_count           = var.reuse_iam == false ? var.cc_count : 1
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  global_tags         = local.global_tags
  cc_callhome_enabled = var.cc_callhome_enabled
  secret_name         = var.secret_name

  byo_iam = var.byo_iam
  # optional inputs. only required if byo_iam set to true
  byo_iam_instance_profile_id = var.byo_iam_instance_profile_id
  # optional inputs. only required if byo_iam set to true
}


################################################################################
# 4. Create Security Group and rules to be assigned to CC mgmt and and service 
#    interface(s). Default behavior will create 1 of each SG resource per CC VM. 
#    Set variable "reuse_security_group" to true if you would like a single 
#    security group created and assigned to ALL Cloud Connectors instead.
################################################################################
module "cc_sg" {
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


################################################################################
# 5. Create Lambda for HA route failover between a pair of Cloud Connectors.
#    If deploying more than a single pair of Cloud Connectors, you will need to: 
#       1. copy this module reference
#       2. replace the values for cc_vm1_id, cc_vm2_id and potentially 
#          cc_vm1_snid and cc_vm2_snid
#       3. define a new list of route table IDs for cc_vm1_rte_list/cc_vm2_rte_list 
#          inline or by creating new variables. E.g. workload_route_table_ids_to_cc_3, etc.
#
#    *Note* - Lambda is not required for single/non-HA deployments. You will need 
#             to at least specify an existing VPC ID though for workload route 
#             table selection logic to work.
################################################################################
module "cc_lambda" {
  count           = var.byo_vpc == true ? 1 : 0
  source          = "../../modules/terraform-zscc-lambda-aws"
  name_prefix     = var.name_prefix
  resource_tag    = random_string.suffix.result
  global_tags     = local.global_tags
  vpc_id          = module.network.vpc_id
  cc_vm1_id       = module.cc_vm.id[0]
  cc_vm2_id       = module.cc_vm.id[1]
  cc_subnet_ids   = module.network.cc_subnet_ids
  cc_vm1_rte_list = var.workload_route_table_ids_to_cc_1
  cc_vm2_rte_list = var.workload_route_table_ids_to_cc_2
  http_probe_port = var.http_probe_port
}


################################################################################
# 6. Create Route 53 Resolver Rules and Endpoints for utilization with DNS 
#    redirection to facilitate Cloud Connector ZPA service.
#    This can optionally be enabled/disabled per variable "zpa_enabled".
################################################################################
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


################################################################################
# Validation for Cloud Connector instance size and EC2 Instance Type 
# compatibilty. Terraform does not have a good/native way to raise an error at 
# the moment, so this will trigger off an invalid count value if there is an 
# improper deployment configuration.
################################################################################
resource "null_resource" "cc_error_checker" {
  count = local.valid_cc_create ? 0 : "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> ../errorlog.txt
EOF
  }
}
