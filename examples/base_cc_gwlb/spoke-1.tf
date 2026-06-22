################################################################################
# Spoke 1 VPC — Workload VPC for TGW Hub-and-Spoke topology
#
# All resources are created only when tgw_enabled = true.
# Workload traffic is routed 0.0.0.0/0 → TGW for centralized inspection in
# the Hub VPC. There is NO local GWLB endpoint in this spoke.
#
# Subnet layout (derived from spoke_1_vpc_cidr, default 10.1.0.0/16):
#   public_subnet      10.1.101.0/24  — bastion host (1 subnet, AZ1 only)
#   workload_subnet[n] 10.1.(1+n).0/24 — workload VMs (1 per AZ)
################################################################################


################################################################################
# Spoke 1 VPC + Internet Gateway
################################################################################
resource "aws_vpc" "spoke_1" {
  count                = var.tgw_enabled ? 1 : 0
  cidr_block           = var.spoke_1_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-1-vpc-${random_string.suffix.result}"
  })
}

resource "aws_internet_gateway" "spoke_1_igw" {
  count  = var.tgw_enabled ? 1 : 0
  vpc_id = aws_vpc.spoke_1[0].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-1-igw-${random_string.suffix.result}"
  })
}


################################################################################
# Spoke 1 Subnets
################################################################################
resource "aws_subnet" "spoke_1_public" {
  count             = var.tgw_enabled ? 1 : 0
  vpc_id            = aws_vpc.spoke_1[0].id
  cidr_block        = cidrsubnet(var.spoke_1_vpc_cidr, 8, 101)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-1-public-subnet-az1-${random_string.suffix.result}"
  })
}

resource "aws_subnet" "spoke_1_workload" {
  count             = var.tgw_enabled ? var.az_count : 0
  vpc_id            = aws_vpc.spoke_1[0].id
  cidr_block        = cidrsubnet(var.spoke_1_vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-1-workload-subnet-az${count.index + 1}-${random_string.suffix.result}"
  })
}


################################################################################
# Spoke 1 Route Tables
################################################################################
resource "aws_route_table" "spoke_1_public_rt" {
  count  = var.tgw_enabled ? 1 : 0
  vpc_id = aws_vpc.spoke_1[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.spoke_1_igw[0].id
  }

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-1-public-rt-${random_string.suffix.result}"
  })
}

resource "aws_route_table_association" "spoke_1_public_rt_assoc" {
  count          = var.tgw_enabled ? 1 : 0
  subnet_id      = aws_subnet.spoke_1_public[0].id
  route_table_id = aws_route_table.spoke_1_public_rt[0].id
}

resource "aws_route_table" "spoke_1_workload_rt" {
  count  = var.tgw_enabled ? var.az_count : 0
  vpc_id = aws_vpc.spoke_1[0].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-1-workload-rt-az${count.index + 1}-${random_string.suffix.result}"
  })
}

resource "aws_route_table_association" "spoke_1_workload_rt_assoc" {
  count          = var.tgw_enabled ? var.az_count : 0
  subnet_id      = aws_subnet.spoke_1_workload[count.index].id
  route_table_id = aws_route_table.spoke_1_workload_rt[count.index].id
}

resource "aws_route" "spoke_1_workload_to_tgw" {
  count                  = var.tgw_enabled ? var.az_count : 0
  route_table_id         = aws_route_table.spoke_1_workload_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.tgw[0].tgw_id

  depends_on = [module.tgw]
}


################################################################################
# Spoke 1 Bastion Host
################################################################################
module "spoke_1_bastion" {
  count                     = var.tgw_enabled ? 1 : 0
  source                    = "../../modules/terraform-zscc-bastion-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = aws_vpc.spoke_1[0].id
  public_subnet             = aws_subnet.spoke_1_public[0].id
  instance_key              = aws_key_pair.deployer.key_name
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
  bastion_iam_role_name     = "spoke-1-bastion-iam-role-${random_string.suffix.result}"
}


################################################################################
# Spoke 1 Workload VMs
################################################################################
module "spoke_1_workload" {
  count          = var.tgw_enabled ? 1 : 0
  workload_count = var.workload_count
  source         = "../../modules/terraform-zscc-workload-aws"
  name_prefix    = "${var.name_prefix}-spoke-1-workload"
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  vpc_id         = aws_vpc.spoke_1[0].id
  subnet_id      = aws_subnet.spoke_1_workload[*].id
  instance_key   = aws_key_pair.deployer.key_name
}
