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
  cc_service_enis   = module.cc_vm.service_eni_1
  az_count          = var.az_count
  vpc_cidr          = var.vpc_cidr
  public_subnets    = var.public_subnets
  workloads_subnets = var.workloads_subnets
  cc_subnets        = var.cc_subnets
  route53_subnets   = var.route53_subnets
  zpa_enabled       = var.zpa_enabled
  gwlb_enabled      = var.gwlb_enabled
  gwlb_endpoint_ids = module.gwlb_endpoint.gwlbe
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


################################################################################
# 4. Create specified number CC VMs per cc_count which will span equally across 
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
# 5. Create IAM Policy, Roles, and Instance Profiles to be assigned to CC. 
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
}


################################################################################
# 6. Create Security Group and rules to be assigned to CC mgmt and and service 
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
}


################################################################################
# 7. Create GWLB in all CC subnets/availability zones. Create a Target Group 
#    and attach primary service IP from all created CCs as registered targets.
################################################################################
module "gwlb" {
  source                   = "../../modules/terraform-zscc-gwlb-aws"
  gwlb_name                = "${var.name_prefix}-cc-gwlb-${random_string.suffix.result}"
  target_group_name        = "${var.name_prefix}-cc-target-${random_string.suffix.result}"
  global_tags              = local.global_tags
  vpc_id                   = module.network.vpc_id
  cc_subnet_ids            = module.network.cc_subnet_ids
  cc_small_service_ips     = module.cc_vm.cc_service_private_ip
  cc_med_lrg_service_1_ips = module.cc_vm.cc_med_lrg_service_1_private_ip
  cc_med_lrg_service_2_ips = module.cc_vm.cc_med_lrg_service_2_private_ip
  cc_lrg_service_3_ips     = module.cc_vm.cc_lrg_service_3_private_ip
  cc_instance_size         = var.cc_instance_size
  http_probe_port          = var.http_probe_port
  health_check_interval    = var.health_check_interval
  healthy_threshold        = var.healthy_threshold
  unhealthy_threshold      = var.unhealthy_threshold
  cross_zone_lb_enabled    = var.cross_zone_lb_enabled
  deregistration_delay     = var.deregistration_delay
  flow_stickiness          = var.flow_stickiness
  rebalance_enabled        = var.rebalance_enabled
}


################################################################################
# 8. Create a VPC Endpoint Service associated with GWLB and 1x GWLB Endpoint 
#    per Cloud Connector subnet/availability zone.
################################################################################
module "gwlb_endpoint" {
  source              = "../../modules/terraform-zscc-gwlbendpoint-aws"
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  global_tags         = local.global_tags
  vpc_id              = module.network.vpc_id
  subnet_ids          = module.network.cc_subnet_ids
  gwlb_arn            = module.gwlb.gwlb_arn
  acceptance_required = var.acceptance_required
  allowed_principals  = var.allowed_principals
}


################################################################################
# 9. Create Route 53 Resolver Rules and Endpoints for utilization with DNS 
#    redirection to facilitate Cloud Connector ZPA service.
################################################################################
module "route53" {
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
