################################################################################
# Hub VPC — Network infrastructure for CC/GWLB/TGW centralized inspection
#
# Subnet layout per AZ (all derived from hub_vpc_cidr, default 10.0.0.0/16):
#   public_subnet[n]        10.0.(101+n).0/24  — 1 NAT GW per AZ lives here
#   tgw_attach_subnet[n]    10.0.(1+n).0/24    — TGW ENIs land here
#   gwlb_endpoint_subnet[n] 10.0.(10+n).0/24   — GWLB Endpoint ENI per AZ
#   cc_subnet[n]            10.0.(200+n).0/24  — Cloud Connector VMs per AZ
#
# Route tables (one per AZ where applicable):
#   public_rt[n]       : 0.0.0.0/0 → IGW
#   tgw_attach_rt[n]   : 0.0.0.0/0 → GWLB Endpoint[n]  ← key traffic steering
#   gwlb_endpoint_rt[n]: 0.0.0.0/0 → NAT GW[n]  +  spoke CIDRs → TGW  ← return path fix
#   cc_rt[n]           : 0.0.0.0/0 → NAT GW[n]          ← matches base_cc_gwlb
################################################################################

################################################################################
# Hub VPC
################################################################################
resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-vpc-${random_string.suffix.result}"
  })
}


################################################################################
# Internet Gateway (for NAT GW and CC egress)
################################################################################
resource "aws_internet_gateway" "hub_igw" {
  vpc_id = aws_vpc.hub.id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-igw-${random_string.suffix.result}"
  })
}


################################################################################
# Elastic IPs + NAT Gateways — 1 per AZ, placed in public subnets
################################################################################
resource "aws_eip" "hub_ngw_eip" {
  count  = var.az_count
  domain = "vpc"

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-ngw-eip-az${count.index + 1}-${random_string.suffix.result}"
  })

  depends_on = [aws_internet_gateway.hub_igw]
}

resource "aws_nat_gateway" "hub_ngw" {
  count         = var.az_count
  allocation_id = aws_eip.hub_ngw_eip[count.index].id
  subnet_id     = aws_subnet.hub_public[count.index].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-ngw-az${count.index + 1}-${random_string.suffix.result}"
  })

  depends_on = [aws_internet_gateway.hub_igw]
}


################################################################################
# Subnets — 1 per AZ for all subnet types
################################################################################

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Public subnets — 1 per AZ, NAT GW lives here
resource "aws_subnet" "hub_public" {
  count             = var.az_count
  vpc_id            = aws_vpc.hub.id
  cidr_block        = var.public_subnets != null ? var.public_subnets[count.index] : cidrsubnet(var.hub_vpc_cidr, 8, count.index + 101)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-public-subnet-az${count.index + 1}-${random_string.suffix.result}"
  })
}

# TGW attachment subnets — 1 per AZ, TGW ENIs land here
resource "aws_subnet" "hub_tgw_attach" {
  count             = var.az_count
  vpc_id            = aws_vpc.hub.id
  cidr_block        = cidrsubnet(var.hub_vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-tgw-attach-subnet-az${count.index + 1}-${random_string.suffix.result}"
  })
}

# GWLB endpoint subnets — 1 per AZ, GWLB Endpoint ENI lives here
resource "aws_subnet" "hub_gwlb_endpoint" {
  count             = var.az_count
  vpc_id            = aws_vpc.hub.id
  cidr_block        = cidrsubnet(var.hub_vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-gwlb-endpoint-subnet-az${count.index + 1}-${random_string.suffix.result}"
  })
}

# CC subnets — 1 per AZ, Cloud Connector VMs live here
resource "aws_subnet" "hub_cc" {
  count             = var.az_count
  vpc_id            = aws_vpc.hub.id
  cidr_block        = var.cc_subnets != null ? var.cc_subnets[count.index] : cidrsubnet(var.hub_vpc_cidr, 8, count.index + 200)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-cc-subnet-az${count.index + 1}-${random_string.suffix.result}"
  })
}


################################################################################
# Route Tables and Routes
################################################################################

# --- Public RT: IGW egress (1 shared RT for all public subnets) ---
resource "aws_route_table" "hub_public_rt" {
  vpc_id = aws_vpc.hub.id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-public-rt-${random_string.suffix.result}"
  })
}

resource "aws_route" "hub_public_to_igw" {
  route_table_id         = aws_route_table.hub_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hub_igw.id
}

resource "aws_route_table_association" "hub_public_rt_assoc" {
  count          = var.az_count
  subnet_id      = aws_subnet.hub_public[count.index].id
  route_table_id = aws_route_table.hub_public_rt.id
}


# --- TGW Attach RT: 1 per AZ — steer ingress from TGW → GWLB Endpoint in same AZ ---
resource "aws_route_table" "hub_tgw_attach_rt" {
  count  = var.az_count
  vpc_id = aws_vpc.hub.id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-tgw-attach-rt-az${count.index + 1}-${random_string.suffix.result}"
  })
}

resource "aws_route" "hub_tgw_attach_to_gwlbe" {
  count                  = var.az_count
  route_table_id         = aws_route_table.hub_tgw_attach_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = module.gwlb_endpoint.gwlbe[count.index]

  depends_on = [module.gwlb_endpoint]
}

resource "aws_route_table_association" "hub_tgw_attach_rt_assoc" {
  count          = var.az_count
  subnet_id      = aws_subnet.hub_tgw_attach[count.index].id
  route_table_id = aws_route_table.hub_tgw_attach_rt[count.index].id
}


# --- GWLB Endpoint RT: 1 per AZ — post-inspection egress to NAT GW in same AZ ---
resource "aws_route_table" "hub_gwlb_endpoint_rt" {
  count  = var.az_count
  vpc_id = aws_vpc.hub.id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-gwlb-endpoint-rt-az${count.index + 1}-${random_string.suffix.result}"
  })
}

resource "aws_route" "hub_gwlb_endpoint_to_nat" {
  count                  = var.az_count
  route_table_id         = aws_route_table.hub_gwlb_endpoint_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hub_ngw[count.index].id
}

resource "aws_route_table_association" "hub_gwlb_endpoint_rt_assoc" {
  count          = var.az_count
  subnet_id      = aws_subnet.hub_gwlb_endpoint[count.index].id
  route_table_id = aws_route_table.hub_gwlb_endpoint_rt[count.index].id
}


# --- CC RT: 1 per AZ — 0.0.0.0/0 → NAT GW in same AZ (matches base_cc_gwlb) ---
resource "aws_route_table" "hub_cc_rt" {
  count  = var.az_count
  vpc_id = aws_vpc.hub.id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-hub-cc-rt-az${count.index + 1}-${random_string.suffix.result}"
  })
}

resource "aws_route" "hub_cc_to_nat" {
  count                  = var.az_count
  route_table_id         = aws_route_table.hub_cc_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hub_ngw[count.index].id
}

resource "aws_route_table_association" "hub_cc_rt_assoc" {
  count          = var.az_count
  subnet_id      = aws_subnet.hub_cc[count.index].id
  route_table_id = aws_route_table.hub_cc_rt[count.index].id
}
