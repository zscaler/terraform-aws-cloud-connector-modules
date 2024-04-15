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
    Owner     = var.owner_tag
    ManagedBy = "terraform"
    Vendor    = "Zscaler"
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
  cc_subnets        = var.cc_subnets
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
# 4. Create specified number CC VMs per min_size / max_size which will span 
#    equally across designated availability zones per az_count. # E.g. min_size 
#    set to 4 and az_count set to 2 will create 2x CCs in AZ1 and 2x CCs in AZ2
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


# Create the specified CC VMs via Launch Template and Autoscaling Group
module "cc_asg" {
  source                    = "../../modules/terraform-zscc-asg-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  cc_subnet_ids             = module.network.cc_subnet_ids
  zonal_asg_enabled         = var.zonal_asg_enabled
  ccvm_instance_type        = var.ccvm_instance_type
  cc_instance_size          = var.cc_instance_size
  instance_key              = aws_key_pair.deployer.key_name
  user_data                 = local.userdata
  iam_instance_profile      = module.cc_iam.iam_instance_profile_id
  mgmt_security_group_id    = module.cc_sg.mgmt_security_group_id
  service_security_group_id = module.cc_sg.service_security_group_id
  ami_id                    = contains(var.ami_id, "") ? [data.aws_ami.cloudconnector.id] : var.ami_id
  ebs_volume_type           = var.ebs_volume_type
  ebs_encryption_enabled    = var.ebs_encryption_enabled
  byo_kms_key_alias         = var.byo_kms_key_alias

  max_size                  = var.max_size
  min_size                  = var.min_size
  target_group_arn          = module.gwlb.target_group_arn
  target_cpu_util_value     = var.target_cpu_util_value
  health_check_grace_period = var.health_check_grace_period
  instance_warmup           = var.instance_warmup
  protect_from_scale_in     = var.protect_from_scale_in
  launch_template_version   = var.launch_template_version

  warm_pool_enabled = var.warm_pool_enabled
  ### only utilzed if warm_pool_enabled set to true ###
  warm_pool_state                            = var.warm_pool_state
  warm_pool_min_size                         = var.warm_pool_min_size
  warm_pool_max_group_prepared_capacity      = var.warm_pool_max_group_prepared_capacity
  reuse_on_scale_in                          = var.reuse_on_scale_in
  lifecyclehook_instance_launch_wait_time    = var.lifecyclehook_instance_launch_wait_time
  lifecyclehook_instance_terminate_wait_time = var.lifecyclehook_instance_terminate_wait_time
  ### only utilzed if warm_pool_enabled set to true ###

  sns_enabled        = var.sns_enabled
  sns_email_list     = var.sns_email_list
  byo_sns_topic      = var.byo_sns_topic
  byo_sns_topic_name = var.byo_sns_topic_name

  depends_on = [
    local_file.user_data_file,
    null_resource.cc_error_checker,
  ]
}


################################################################################
# 5. Create IAM Policy, Roles, and Instance Profiles to be assigned to CC
################################################################################
module "cc_iam" {
  source             = "../../modules/terraform-zscc-iam-aws"
  name_prefix        = var.name_prefix
  resource_tag       = random_string.suffix.result
  global_tags        = local.global_tags
  asg_enabled        = var.asg_enabled
  secret_name        = var.secret_name
  cloud_tags_enabled = var.cloud_tags_enabled
}


################################################################################
# 6. Create Security Group and rules to be assigned to CC mgmt and and service 
#    interface(s)
################################################################################
module "cc_sg" {
  source                   = "../../modules/terraform-zscc-sg-aws"
  name_prefix              = var.name_prefix
  resource_tag             = random_string.suffix.result
  global_tags              = local.global_tags
  vpc_id                   = module.network.vpc_id
  http_probe_port          = var.http_probe_port
  mgmt_ssh_enabled         = var.mgmt_ssh_enabled
  all_ports_egress_enabled = var.all_ports_egress_enabled
  support_access_enabled   = var.support_access_enabled
  zssupport_server         = var.zssupport_server
}


################################################################################
# 7. Create GWLB in all CC subnets/availability zones. Create a Target Group 
#    used by cc_asg module to auto associate instances
################################################################################
module "gwlb" {
  source                = "../../modules/terraform-zscc-gwlb-aws"
  gwlb_name             = "${var.name_prefix}-cc-gwlb-${random_string.suffix.result}"
  target_group_name     = "${var.name_prefix}-cc-target-${random_string.suffix.result}"
  global_tags           = local.global_tags
  vpc_id                = module.network.vpc_id
  cc_subnet_ids         = module.network.cc_subnet_ids
  http_probe_port       = var.http_probe_port
  health_check_interval = var.health_check_interval
  healthy_threshold     = var.healthy_threshold
  unhealthy_threshold   = var.unhealthy_threshold
  cross_zone_lb_enabled = var.cross_zone_lb_enabled
  asg_enabled           = var.asg_enabled
  deregistration_delay  = var.deregistration_delay
  flow_stickiness       = var.flow_stickiness
  rebalance_enabled     = var.rebalance_enabled
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
# 9. Create Lambda Function for Autoscaling support
################################################################################
module "asg_lambda" {
  source                  = "../../modules/terraform-zscc-asg-lambda-aws"
  name_prefix             = var.name_prefix
  resource_tag            = random_string.suffix.result
  global_tags             = local.global_tags
  cc_vm_prov_url          = var.cc_vm_prov_url
  secret_name             = var.secret_name
  autoscaling_group_names = module.cc_asg.autoscaling_group_ids
  asg_lambda_filename     = var.asg_lambda_filename
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
