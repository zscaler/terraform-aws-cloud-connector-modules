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
# 1. Create Bastion Host in Hub VPC public subnet for CC SSH jump access
################################################################################
module "bastion" {
  source                    = "../../modules/terraform-zscc-bastion-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = aws_vpc.hub.id
  public_subnet             = aws_subnet.hub_public[0].id
  instance_key              = aws_key_pair.deployer.key_name
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
}


################################################################################
# 2. Cloud Connector VM bootstrap user_data
################################################################################
locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
SECRET_NAME=${var.secret_name}
HTTP_PROBE_PORT=${var.http_probe_port}
USERDATA
}

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


################################################################################
# 3. Create specified number of CC appliances in Hub VPC CC subnet
#    CC subnet route table: 0.0.0.0/0 → NAT GW (identical to base_cc_gwlb design)
################################################################################
module "cc_vm" {
  source                    = "../../modules/terraform-zscc-ccvm-aws"
  cc_count                  = var.cc_count
  ami_id                    = contains(var.ami_id, "") ? [data.aws_ami.cloudconnector.id] : var.ami_id
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  mgmt_subnet_id            = aws_subnet.hub_cc[*].id
  service_subnet_id         = aws_subnet.hub_cc[*].id
  instance_key              = aws_key_pair.deployer.key_name
  user_data                 = local.userdata
  ccvm_instance_type        = var.ccvm_instance_type
  cc_instance_size          = var.cc_instance_size
  iam_instance_profile      = module.cc_iam.iam_instance_profile_id
  mgmt_security_group_id    = module.cc_sg.mgmt_security_group_id
  service_security_group_id = module.cc_sg.service_security_group_id
  ebs_volume_type           = var.ebs_volume_type
  ebs_encryption_enabled    = var.ebs_encryption_enabled
  byo_kms_key_alias         = var.byo_kms_key_alias

  depends_on = [
    local_file.user_data_file,
    null_resource.cc_error_checker,
  ]
}


################################################################################
# 4. Create IAM Policy, Roles, and Instance Profiles for CC
################################################################################
module "cc_iam" {
  source             = "../../modules/terraform-zscc-iam-aws"
  iam_count          = var.reuse_iam == false ? var.cc_count : 1
  name_prefix        = var.name_prefix
  resource_tag       = random_string.suffix.result
  global_tags        = local.global_tags
  secret_name        = var.secret_name
  cloud_tags_enabled = var.cloud_tags_enabled
}


################################################################################
# 5. Create Security Groups for CC mgmt and service interfaces
################################################################################
module "cc_sg" {
  source                   = "../../modules/terraform-zscc-sg-aws"
  sg_count                 = var.reuse_security_group == false ? var.cc_count : 1
  name_prefix              = var.name_prefix
  resource_tag             = random_string.suffix.result
  global_tags              = local.global_tags
  vpc_id                   = aws_vpc.hub.id
  http_probe_port          = var.http_probe_port
  mgmt_ssh_enabled         = var.mgmt_ssh_enabled
  all_ports_egress_enabled = var.all_ports_egress_enabled
}


################################################################################
# 6. Create GWLB in Hub VPC CC subnet. Register CC service IPs as targets.
#    GWLB load balances traffic to CC NVAs using Geneve tunneling (port 6081).
################################################################################
module "gwlb" {
  source                = "../../modules/terraform-zscc-gwlb-aws"
  gwlb_name             = "${var.name_prefix}-cc-gwlb-${random_string.suffix.result}"
  target_group_name     = "${var.name_prefix}-cc-target-${random_string.suffix.result}"
  global_tags           = local.global_tags
  vpc_id                = aws_vpc.hub.id
  cc_subnet_ids         = aws_subnet.hub_cc[*].id
  cc_service_ips        = module.cc_vm.forwarding_ip
  http_probe_port       = var.http_probe_port
  health_check_interval = var.health_check_interval
  healthy_threshold     = var.healthy_threshold
  unhealthy_threshold   = var.unhealthy_threshold
  cross_zone_lb_enabled = var.cross_zone_lb_enabled
  deregistration_delay  = var.deregistration_delay
  flow_stickiness       = var.flow_stickiness
  rebalance_enabled     = var.rebalance_enabled
}


################################################################################
# 7. Create GWLB Endpoint Service (backed by GWLB) and GWLB Endpoint in the
#    Hub VPC GWLB endpoint subnet. Traffic from TGW attach subnet is steered
#    here via the tgw_attach_rt route (0.0.0.0/0 → this endpoint).
################################################################################
module "gwlb_endpoint" {
  source              = "../../modules/terraform-zscc-gwlbendpoint-aws"
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  global_tags         = local.global_tags
  vpc_id              = aws_vpc.hub.id
  subnet_ids          = aws_subnet.hub_gwlb_endpoint[*].id
  gwlb_arn            = module.gwlb.gwlb_arn
  acceptance_required = var.acceptance_required
  allowed_principals  = var.allowed_principals
}


################################################################################
# Validation for Cloud Connector instance size and EC2 Instance Type 
# compatibilty.
################################################################################
resource "null_resource" "cc_error_checker" {
  count = local.valid_cc_create ? 0 : "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> ../errorlog.txt
EOF
  }
}
