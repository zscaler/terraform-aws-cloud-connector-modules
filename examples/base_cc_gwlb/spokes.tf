################################################################################
# Spoke VPCs — Workload VPCs for TGW Hub-and-Spoke topology
#
# All resources are created only when tgw_enabled = true.
# Each spoke entry in var.spokes defines one workload VPC:
#   - VPC + IGW
#   - 1 public subnet (bastion, AZ1 only) at offset 101
#   - az_count workload subnets at offsets 1..az_count
#   - Public RT → IGW; workload RTs → TGW (default route)
#   - Bastion host (terraform-zscc-bastion-aws module)
#   - Workload VMs (terraform-zscc-workload-aws module)
#
# var.spokes schema:
#   {
#     "spoke-1" = { cidr = "10.1.0.0/16", name = "spoke-1" }
#     "spoke-2" = { cidr = "10.2.0.0/16", name = "spoke-2" }
#   }
################################################################################

locals {
  # Only expand spoke resources when TGW mode is active
  active_spokes = var.tgw_enabled ? var.spokes : {}

  # Flatten spokes × AZs for per-AZ workload subnet creation
  spoke_az_pairs = var.tgw_enabled ? flatten([
    for spoke_key, spoke in var.spokes : [
      for az_idx in range(var.az_count) : {
        key      = "${spoke_key}-az${az_idx + 1}"
        spoke    = spoke_key
        az_index = az_idx
        cidr     = spoke.cidr
        name     = spoke.name
      }
    ]
  ]) : []
}


################################################################################
# Spoke VPCs + Internet Gateways
################################################################################
resource "aws_vpc" "spoke" {
  for_each             = local.active_spokes
  cidr_block           = each.value.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-${each.value.name}-vpc-${random_string.suffix.result}"
  })
}

resource "aws_internet_gateway" "spoke" {
  for_each = local.active_spokes
  vpc_id   = aws_vpc.spoke[each.key].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-${each.value.name}-igw-${random_string.suffix.result}"
  })
}


################################################################################
# Spoke Public Subnets (bastion — 1 per spoke, AZ1 only)
################################################################################
resource "aws_subnet" "spoke_public" {
  for_each          = local.active_spokes
  vpc_id            = aws_vpc.spoke[each.key].id
  cidr_block        = cidrsubnet(each.value.cidr, 8, 101)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-${each.value.name}-public-subnet-az1-${random_string.suffix.result}"
  })
}

resource "aws_route_table" "spoke_public" {
  for_each = local.active_spokes
  vpc_id   = aws_vpc.spoke[each.key].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.spoke[each.key].id
  }

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-${each.value.name}-public-rt-${random_string.suffix.result}"
  })
}

resource "aws_route_table_association" "spoke_public" {
  for_each       = local.active_spokes
  subnet_id      = aws_subnet.spoke_public[each.key].id
  route_table_id = aws_route_table.spoke_public[each.key].id
}


################################################################################
# Spoke Workload Subnets (az_count per spoke)
################################################################################
resource "aws_subnet" "spoke_workload" {
  for_each = {
    for pair in local.spoke_az_pairs : pair.key => pair
  }

  vpc_id            = aws_vpc.spoke[each.value.spoke].id
  cidr_block        = cidrsubnet(each.value.cidr, 8, each.value.az_index + 1)
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index]

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-${each.value.name}-workload-subnet-az${each.value.az_index + 1}-${random_string.suffix.result}"
  })
}

resource "aws_route_table" "spoke_workload" {
  for_each = {
    for pair in local.spoke_az_pairs : pair.key => pair
  }

  vpc_id = aws_vpc.spoke[each.value.spoke].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-${each.value.name}-workload-rt-az${each.value.az_index + 1}-${random_string.suffix.result}"
  })
}

resource "aws_route_table_association" "spoke_workload" {
  for_each = {
    for pair in local.spoke_az_pairs : pair.key => pair
  }

  subnet_id      = aws_subnet.spoke_workload[each.key].id
  route_table_id = aws_route_table.spoke_workload[each.key].id
}

resource "aws_route" "spoke_workload_to_tgw" {
  for_each = {
    for pair in local.spoke_az_pairs : pair.key => pair
  }

  route_table_id         = aws_route_table.spoke_workload[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.tgw[0].tgw_id

  depends_on = [module.tgw]
}


################################################################################
# Spoke Bastion Hosts
################################################################################
module "spoke_bastion" {
  for_each = local.active_spokes

  source                    = "../../modules/terraform-zscc-bastion-aws"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = aws_vpc.spoke[each.key].id
  public_subnet             = aws_subnet.spoke_public[each.key].id
  instance_key              = aws_key_pair.deployer.key_name
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
  bastion_iam_role_name     = "${each.value.name}-bastion-iam-role-${random_string.suffix.result}"
}


################################################################################
# Spoke Workload VMs
################################################################################
module "spoke_workload" {
  for_each = local.active_spokes

  source         = "../../modules/terraform-zscc-workload-aws"
  workload_count = var.workload_count
  name_prefix    = "${var.name_prefix}-${each.value.name}-workload"
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  vpc_id         = aws_vpc.spoke[each.key].id
  subnet_id = [
    for pair in local.spoke_az_pairs :
    aws_subnet.spoke_workload[pair.key].id
    if pair.spoke == each.key
  ]
  instance_key = aws_key_pair.deployer.key_name
}
