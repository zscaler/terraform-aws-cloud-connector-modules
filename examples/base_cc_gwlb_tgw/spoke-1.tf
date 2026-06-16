################################################################################
# Spoke 1 VPC — Workload VMs + TGW route to Hub for centralized inspection
# Traffic path: Workload → TGW → Hub TGW attach subnet → GWLB Endpoint → CC
################################################################################

################################################################################
# 1. Create Spoke 1 VPC network infrastructure
################################################################################
resource "aws_vpc" "spoke_1" {
  cidr_block           = var.spoke_1_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.global_tags, { Name = "${var.name_prefix}-spoke-1-vpc-${random_string.suffix.result}" })
}

resource "aws_internet_gateway" "spoke_1_igw" {
  vpc_id = aws_vpc.spoke_1.id

  tags = merge(local.global_tags, { Name = "${var.name_prefix}-spoke-1-igw-${random_string.suffix.result}" })
}

data "aws_availability_zones" "spoke_1_available" {
  state = "available"
}

resource "aws_subnet" "spoke_1_public" {
  vpc_id                  = aws_vpc.spoke_1.id
  cidr_block              = cidrsubnet(var.spoke_1_vpc_cidr, 8, 101)
  availability_zone       = data.aws_availability_zones.spoke_1_available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.global_tags, { Name = "${var.name_prefix}-spoke-1-public-subnet-${random_string.suffix.result}" })
}

resource "aws_subnet" "spoke_1_workload" {
  count             = var.az_count
  vpc_id            = aws_vpc.spoke_1.id
  cidr_block        = cidrsubnet(var.spoke_1_vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.spoke_1_available.names[count.index]

  tags = merge(local.global_tags, { Name = "${var.name_prefix}-spoke-1-workload-subnet-${count.index + 1}-${random_string.suffix.result}" })
}

resource "aws_route_table" "spoke_1_public_rt" {
  vpc_id = aws_vpc.spoke_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.spoke_1_igw.id
  }

  tags = merge(local.global_tags, { Name = "${var.name_prefix}-spoke-1-public-rt-${random_string.suffix.result}" })
}

resource "aws_route_table_association" "spoke_1_public_rta" {
  subnet_id      = aws_subnet.spoke_1_public.id
  route_table_id = aws_route_table.spoke_1_public_rt.id
}

resource "aws_route_table" "spoke_1_workload_rt" {
  count  = var.az_count
  vpc_id = aws_vpc.spoke_1.id

  tags = merge(local.global_tags, { Name = "${var.name_prefix}-spoke-1-workload-rt-${count.index + 1}-${random_string.suffix.result}" })
}

resource "aws_route_table_association" "spoke_1_workload_rta" {
  count          = var.az_count
  subnet_id      = aws_subnet.spoke_1_workload[count.index].id
  route_table_id = aws_route_table.spoke_1_workload_rt[count.index].id
}


################################################################################
# 2. Create Bastion Host for workload SSH jump access in Spoke 1 VPC
################################################################################
module "spoke_1_bastion" {
  source                    = "../../modules/terraform-zscc-bastion-aws"
  name_prefix               = "${var.name_prefix}-sp1"
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = aws_vpc.spoke_1.id
  public_subnet             = aws_subnet.spoke_1_public.id
  instance_key              = aws_key_pair.deployer.key_name
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
}


################################################################################
# 3. Create Workload Hosts in Spoke 1 VPC
################################################################################
module "spoke_1_workload" {
  workload_count = var.workload_count
  source         = "../../modules/terraform-zscc-workload-aws"
  name_prefix    = "${var.name_prefix}-sp1-workload"
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  vpc_id         = aws_vpc.spoke_1.id
  subnet_id      = aws_subnet.spoke_1_workload[*].id
  instance_key   = aws_key_pair.deployer.key_name
}


################################################################################
# 4. Route workload traffic to TGW for centralized inspection in Hub VPC
#    Replaces the local GWLB endpoint route used in base_cc_gwlb.
#    Traffic path: Workload → TGW → Hub TGW attach subnet → GWLB Endpoint → CC
################################################################################
resource "aws_route" "spoke_1_workload_to_tgw" {
  count                  = var.az_count
  route_table_id         = aws_route_table.spoke_1_workload_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_1]
}
