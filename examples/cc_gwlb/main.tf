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
  gwlb_endpoint_ids = module.gwlb-endpoint.gwlbe
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
  vpc_id                    = module.network.vpc-id
  mgmt_subnet_id            = module.network.cc-subnet-ids
  service_subnet_id         = module.network.cc-subnet-ids
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
  vpc_id       = module.network.vpc-id

  byo_security_group = var.byo_security_group
  # optional inputs. only required if byo_security_group set to true
  byo_mgmt_security_group_id    = var.byo_mgmt_security_group_id
  byo_service_security_group_id = var.byo_service_security_group_id
  # optional inputs. only required if byo_security_group set to true
}


# 5. Create GWLB in all CC subnets. Create 1x GWLB Endpoint per subnet with Endpoint Service. Create Target Group and attach primary service IP from all created Cloud
#    Connectors as registered targets.
module "gwlb" {
  source                   = "../../modules/terraform-zscc-gwlb-aws"
  name_prefix              = var.name_prefix
  resource_tag             = random_string.suffix.result
  global_tags              = local.global_tags
  vpc_id                   = module.network.vpc-id
  cc_subnet_ids            = module.network.cc-subnet-ids
  cc_small_service_ips     = module.cc-vm.cc_service_private_ip
  cc_med_lrg_service_1_ips = module.cc-vm.cc_med_lrg_service_1_private_ip
  cc_med_lrg_service_2_ips = module.cc-vm.cc_med_lrg_service_2_private_ip
  cc_lrg_service_3_ips     = module.cc-vm.cc_lrg_service_3_private_ip
  cc_instance_size         = var.cc_instance_size
  http_probe_port          = var.http_probe_port
  health_check_interval    = var.health_check_interval
  healthy_threshold        = var.healthy_threshold
  unhealthy_threshold      = var.unhealthy_threshold
  cross_zone_lb_enabled    = var.cross_zone_lb_enabled
}


# 6. Create Endpoint Service associated with GWLB and 1x GWLB Endpoint per CC subnet
module "gwlb-endpoint" {
  source       = "../../modules/terraform-zscc-gwlbendpoint-aws"
  name_prefix  = var.name_prefix
  resource_tag = random_string.suffix.result
  global_tags  = local.global_tags
  vpc_id       = module.network.vpc-id
  subnet_ids   = module.network.cc-subnet-ids
  gwlb_arn     = module.gwlb.gwlb_arn
}


# 7. Optional Route53 for ZPA
#    Create Route 53 Resolver Rules and Endpoints for utilization with DNS redirection to facilitate Cloud Connector ZPA service
module "route53" {
  count          = var.zpa_enabled == true ? 1 : 0
  source         = "../../modules/terraform-zscc-route53-aws"
  name_prefix    = var.name_prefix
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  vpc_id         = module.network.vpc-id
  r53_subnet_ids = module.network.route53-subnet-ids
  domain_names   = var.domain_names
  target_address = var.target_address
}


resource "null_resource" "cc-error-checker" {
  count = local.valid_cc_create ? 0 : 1 # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> ../errorlog.txt
EOF
  }
}