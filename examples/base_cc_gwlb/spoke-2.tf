################################################################################
# Spoke 2 VPC — Workload VPC for TGW Hub-and-Spoke topology
#
# All resources are created only when tgw_enabled = true.
# Workload traffic is routed 0.0.0.0/0 → TGW for centralized inspection in
# the Hub VPC. There is NO local GWLB endpoint in this spoke.
#
# Subnet layout (derived from spoke_2_vpc_cidr, default 10.2.0.0/16):
#   public_subnet      10.2.101.0/24  — bastion host (1 subnet, AZ1 only)
#   workload_subnet[n] 10.2.(1+n).0/24 — workload VMs (1 per AZ)
################################################################################


################################################################################
# Spoke 2 VPC + Internet Gateway
################################################################################
resource "aws_vpc" "spoke_2" {
  count                = var.tgw_enabled ? 1 : 0
  cidr_block           = var.spoke_2_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-2-vpc-${random_string.suffix.result}"
  })
}

resource "aws_internet_gateway" "spoke_2_igw" {
  count  = var.tgw_enabled ? 1 : 0
  vpc_id = aws_vpc.spoke_2[0].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-2-igw-${random_string.suffix.result}"
  })
}


################################################################################
# Spoke 2 Subnets
################################################################################
resource "aws_subnet" "spoke_2_public" {
  count             = var.tgw_enabled ? 1 : 0
  vpc_id            = aws_vpc.spoke_2[0].id
  cidr_block        = cidrsubnet(var.spoke_2_vpc_cidr, 8, 101)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-2-public-subnet-az1-${random_string.suffix.result}"
  })
}

resource "aws_subnet" "spoke_2_workload" {
  count             = var.tgw_enabled ? var.az_count : 0
  vpc_id            = aws_vpc.spoke_2[0].id
  cidr_block        = cidrsubnet(var.spoke_2_vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-2-workload-subnet-az${count.index + 1}-${random_string.suffix.result}"
  })
}


################################################################################
# Spoke 2 Route Tables
################################################################################
resource "aws_route_table" "spoke_2_public_rt" {
  count  = var.tgw_enabled ? 1 : 0
  vpc_id = aws_vpc.spoke_2[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.spoke_2_igw[0].id
  }

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-2-public-rt-${random_string.suffix.result}"
  })
}

resource "aws_route_table_association" "spoke_2_public_rt_assoc" {
  count          = var.tgw_enabled ? 1 : 0
  subnet_id      = aws_subnet.spoke_2_public[0].id
  route_table_id = aws_route_table.spoke_2_public_rt[0].id
}

resource "aws_route_table" "spoke_2_workload_rt" {
  count  = var.tgw_enabled ? var.az_count : 0
  vpc_id = aws_vpc.spoke_2[0].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-spoke-2-workload-rt-az${count.index + 1}-${random_string.suffix.result}"
  })
}

resource "aws_route_table_association" "spoke_2_workload_rt_assoc" {
  count          = var.tgw_enabled ? var.az_count : 0
  subnet_id      = aws_subnet.spoke_2_workload[count.index].id
  route_table_id = aws_route_table.spoke_2_workload_rt[count.index].id
}

resource "aws_route" "spoke_2_workload_to_tgw" {
  count                  = var.tgw_enabled ? var.az_count : 0
  route_table_id         = aws_route_table.spoke_2_workload_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw[0].id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_2]
}


################################################################################
# Spoke 2 Bastion Host
################################################################################
module "spoke_2_bastion" {
  count                     = var.tgw_enabled ? 1 : 0
  source                    = "../../modules/terraform-zscc-bastion-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = aws_vpc.spoke_2[0].id
  public_subnet             = aws_subnet.spoke_2_public[0].id
  instance_key              = aws_key_pair.deployer.key_name
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
  bastion_iam_role_name     = "spoke-2-bastion-iam-role-${random_string.suffix.result}"
}


################################################################################
# Spoke 2 Workload VMs
################################################################################
module "spoke_2_workload" {
  count          = var.tgw_enabled ? 1 : 0
  workload_count = var.workload_count
  source         = "../../modules/terraform-zscc-workload-aws"
  name_prefix    = "${var.name_prefix}-spoke-2-workload"
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  vpc_id         = aws_vpc.spoke_2[0].id
  subnet_id      = aws_subnet.spoke_2_workload[*].id
  instance_key   = aws_key_pair.deployer.key_name
}
