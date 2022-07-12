# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Generate a unique random string for resource name assignment and key pair
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

# Map default tags with values to be assigned to all tagged resources
locals {
  global_tags = {
  Owner       = var.owner_tag
  ManagedBy   = "terraform"
  Vendor      = "Zscaler"
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
  algorithm   = var.tls_key_algorithm
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.name_prefix}-key-${random_string.suffix.result}"
  public_key = tls_private_key.key.public_key_openssh

  provisioner "local-exec" {
    command = <<EOF
      echo "${tls_private_key.key.private_key_pem}" > ${var.name_prefix}-key-${random_string.suffix.result}.pem
      chmod 0600 ${var.name_prefix}-key-${random_string.suffix.result}.pem
EOF
  }
}


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
  filename = "user_data"
}


# 1. Network Creation
# Identify availability zones available for region selected
data "aws_availability_zones" "available" {
  state = "available"
}


# Create a new VPC
resource "aws_vpc" "vpc1" {
  count               = var.byo_vpc == false || var.lambda_enabled == false ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-vpc1-${random_string.suffix.result}" }
  )
}

# Or reference an existing VPC
data "aws_vpc" "selected" {
  id = var.byo_vpc == false ? aws_vpc.vpc1.*.id[0] : var.byo_vpc_id
}


# Create an Internet Gateway
resource "aws_internet_gateway" "igw1" {
  count  = var.byo_igw == false ? 1 : 0
  vpc_id = data.aws_vpc.selected.id

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-vpc1-igw-${random_string.suffix.result}" }
  )
}

# Or reference an existing Internet Gateway
data "aws_internet_gateway" "selected" {
  internet_gateway_id = var.byo_igw == false ? aws_internet_gateway.igw1.*.id[0] : var.byo_igw_id
}


# Create equal number of Public/NAT Subnets to how many Cloud Connector subnets exist. This will not be created if var.byo_ngw is set to True
resource "aws_subnet" "pubsubnet" {
  count = var.byo_ngw == false ? length(data.aws_subnet.cc-selected.*.id) : 0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(data.aws_vpc.selected.cidr_block, 8, count.index + 101)
  vpc_id            = data.aws_vpc.selected.id

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-vpc1-public-subnet-${count.index + 1}-${random_string.suffix.result}" }
  )
}


# Create a public Route Table towards IGW. This will not be created if var.byo_ngw is set to True
resource "aws_route_table" "routetablepublic1" {
  count = var.byo_ngw == false ? 1 : 0
  vpc_id = data.aws_vpc.selected.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.selected.internet_gateway_id
  }

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-igw-rt-${random_string.suffix.result}" }
  )
}


# Create equal number of Route Table associations to how many Public subnets exist. This will not be created if var.byo_ngw is set to True
resource "aws_route_table_association" "routetablepublic1" {
  count = var.byo_ngw == false ? length(aws_subnet.pubsubnet.*.id) : 0
  subnet_id      = aws_subnet.pubsubnet.*.id[count.index]
  route_table_id = aws_route_table.routetablepublic1[0].id
}


# Create NAT Gateway and assign EIP per AZ. This will not be created if var.byo_ngw is set to True
resource "aws_eip" "eip" {
  count = var.byo_ngw == false ? length(aws_subnet.pubsubnet.*.id) : 0
  vpc        = true
  depends_on = [data.aws_internet_gateway.selected]

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-eip-az${count.index + 1}-${random_string.suffix.result}" }
  )
}

# Create 1 NAT Gateway per Public Subnet.
resource "aws_nat_gateway" "ngw" {
  count = var.byo_ngw == false ? length(aws_subnet.pubsubnet.*.id) : 0
  allocation_id = aws_eip.eip.*.id[count.index]
  subnet_id     = aws_subnet.pubsubnet.*.id[count.index]
  depends_on    = [data.aws_internet_gateway.selected]
  
  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-vpc1-natgw-az${count.index + 1}-${random_string.suffix.result}" }
  )
}

# Or reference existing NAT Gateways
data "aws_nat_gateway" "selected" {
  count = var.byo_ngw == false ? length(aws_nat_gateway.ngw.*.id) : length(var.byo_ngw_ids)
  id = var.byo_ngw == false ? aws_nat_gateway.ngw.*.id[count.index] : element(var.byo_ngw_ids, count.index)
}



# 2. Create CC network, routing, and appliance
# Create subnet for CC network in X availability zones per az_count variable
resource "aws_subnet" "cc-subnet" {
  count = var.byo_subnets == false ? var.az_count : 0

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(data.aws_vpc.selected.cidr_block, 8, count.index + 200)
  vpc_id            = data.aws_vpc.selected.id

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-vpc1-cc-subnet-${count.index + 1}-${random_string.suffix.result}" }
  )
}

# Or reference existing subnets
data "aws_subnet" "cc-selected" {
count = var.byo_subnets == false ? var.az_count : length(var.byo_subnet_ids)
id = var.byo_subnets == false ? aws_subnet.cc-subnet.*.id[count.index] : element(var.byo_subnet_ids, count.index)
}


# Create Route Tables for CC subnets pointing to NAT Gateway resource in each AZ or however many were specified
resource "aws_route_table" "cc-rt" {
  count = length(data.aws_subnet.cc-selected.*.id)
  vpc_id = data.aws_vpc.selected.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(data.aws_nat_gateway.selected.*.id, count.index)
  }

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-cc-rt-ngw-${count.index + 1}-${random_string.suffix.result}" }
  )
}


# CC subnet NATGW Route Table Association
resource "aws_route_table_association" "cc-rt-asssociation" {
  count          = length(data.aws_subnet.cc-selected.*.id)
  subnet_id      = data.aws_subnet.cc-selected.*.id[count.index]
  route_table_id = aws_route_table.cc-rt.*.id[count.index]
}

resource "null_resource" "cc-error-checker" {
  count = local.valid_cc_create ? 0 : 1 # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> errorlog.txt
EOF
  }
}

# Create X CC VMs per cc_count which will span equally across designated availability zones per az_count
# E.g. cc_count set to 4 and az_count set to 2 or byo_subnet_ids configured for 2 will create 2x CCs in AZ subnet 1 and 2x CCs in AZ subnet 2
module "cc-vm" {
  source              = "../modules/terraform-zscc-aws"
  cc_count            = var.cc_count
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  global_tags         = local.global_tags
  vpc                 = data.aws_vpc.selected.id
  mgmt_subnet_id      = data.aws_subnet.cc-selected.*.id
  service_subnet_id   = data.aws_subnet.cc-selected.*.id
  instance_key        = aws_key_pair.deployer.key_name
  user_data           = local.userdata
  ccvm_instance_type  = var.ccvm_instance_type
  cc_instance_size    = var.cc_instance_size
  cc_callhome_enabled = var.cc_callhome_enabled
}


# 3. Optional Create Lambda for HA between pair of Cloud Connectors. If deploying more than a single pair of Cloud Connectors,
#    you will need to: 
#    1. copy this module reference
#    2. replace the values for cc_vm1_id, cc_vm2_id and potentially cc_vm1_snid and cc_vm2_snid
#    3. define a new list route table IDs for cc_vm1_rte_list/cc_vm2_rte_list inline or by creating new variables
#       e.g workload_route_table_ids_to_cc_3, etc.
#
#    **** Note - Lambda is not required for single or non-redundant deployments. You will need to at least specify an 
#                existing VPC ID though for workload route table selection logic to work

module "cc-lambda" {
  count            = var.lambda_enabled == true && var.byo_vpc == true ? 1 : 0
  source           = "../modules/terraform-zslambda-aws"
  name_prefix      = var.name_prefix
  resource_tag     = random_string.suffix.result
  global_tags      = local.global_tags
  vpc              = data.aws_vpc.selected.id
  cc_vm1_id        = module.cc-vm.id[0]
  cc_vm2_id        = module.cc-vm.id[1]
  cc_vm1_snid      = data.aws_subnet.cc-selected.*.id[0]
  cc_vm2_snid      = data.aws_subnet.cc-selected.*.id[1]
  cc_vm1_rte_list  = var.workload_route_table_ids_to_cc_1
  cc_vm2_rte_list  = var.workload_route_table_ids_to_cc_2
  http_probe_port  = var.http_probe_port
}



# 4. Optional Route53 for ZPA
# Create Route53 Subnets. Defaults to 2 minimum. Modify the count here if you want to create more than 2.
resource "aws_subnet" "r53-subnet" {
  count             = var.zpa_enabled == true ? 2 : 0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(data.aws_vpc.selected.cidr_block, 12, (64 + count.index * 16))
  vpc_id            = data.aws_vpc.selected.id

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-ec-r53-subnet-${count.index + 1}-${random_string.suffix.result}" }
  )
}

# Create Route Table for Route53 routing to CC in the same AZ for DNS redirection
resource "aws_route_table" "rt-r53" {
  count = var.zpa_enabled == true ? length(aws_subnet.r53-subnet.*.id) : 0
  vpc_id = data.aws_vpc.selected.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = element(module.cc-vm.eni, count.index)
  }

  tags = merge(local.global_tags,
        { Name = "${var.name_prefix}-r53-to-ccvm-${count.index + 1}-rt-${random_string.suffix.result}" }
  )
}

# Route53 Subnets Route Table Assocation
resource "aws_route_table_association" "r53-rt-asssociation" {
  count          = var.zpa_enabled == true ? length(aws_subnet.r53-subnet.*.id) : 0
  subnet_id      = aws_subnet.r53-subnet.*.id[count.index]
  route_table_id = aws_route_table.rt-r53.*.id[count.index]
}


module "route53" {
  count           = var.zpa_enabled == true ? 1 : 0
  source          = "../modules/terraform-zsroute53-aws"
  name_prefix     = var.name_prefix
  resource_tag    = random_string.suffix.result
  global_tags     = local.global_tags
  vpc             = data.aws_vpc.selected.id
  r53_subnet_ids  = aws_subnet.r53-subnet.*.id
  domain_names    = var.domain_names
  target_address  = var.target_address
}


############################################################################################################################################
####### Legacy code for reference if customer desires to break cloud connector mgmt and service interfaces out into separate subnets #######
############################################################################################################################################

# create new subnet for CC mgmt n/w
#resource "aws_subnet" "cc-mgmt-subnet" {
#  count = 2
#
#  availability_zone = data.aws_availability_zones.available.names[count.index]
#  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 12, (count.index * 16) + 3936)
#  vpc_id            = aws_vpc.vpc1.id
#
#  tags = map(
#    "Name", "${var.name_prefix}-vpc1-ec-mgmt-subnet-${count.index + 1}-${random_string.suffix.result}",
#    "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}", "shared",
#  )
#}

#CC Mgmt/Service NATGW Route Table
#resource "aws_route_table" "routetable-cc-mgmt-and-service" {
#  count  = 1
#  vpc_id = aws_vpc.vpc1.id
#  route {
#    cidr_block     = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.ngw1.id
#  }
#
#  tags = map(
#    "Name", "${var.name_prefix}-natgw-cc-mgmt-svc-rt-${count.index + 1}-${random_string.suffix.result}",
#    "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}", "shared",
#  )
#}

#CC Mgmt subnet NATGW Route Table Association
#resource "aws_route_table_association" "routetable-cc-mgmt" {
#  count          = 2
#  subnet_id      = aws_subnet.cc-mgmt-subnet.*.id[count.index]
#  route_table_id = aws_route_table.routetable-cc-mgmt-and-service.*.id[0]
#}

# create new subnet for CC service n/w
#resource "aws_subnet" "cc-service-subnet" {
#  count             = 2
#  availability_zone = data.aws_availability_zones.available.names[count.index]
#  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 12, (count.index * 16) + 4000)
#  vpc_id            = aws_vpc.vpc1.id
#
#  tags = map(
#    "Name", "${var.name_prefix}-ec-service-subnet-${count.index + 1}-${random_string.suffix.result}",
#    "zs-edge-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}", "shared",
#  )
#}

#EC Service subnet NATGW Route Table Association
#resource "aws_route_table_association" "routetable-cc-service" {
#  count          = 2
#  subnet_id      = aws_subnet.cc-service-subnet.*.id[count.index]
#  route_table_id = aws_route_table.routetable-cc-mgmt-and-service.*.id[0]
#}