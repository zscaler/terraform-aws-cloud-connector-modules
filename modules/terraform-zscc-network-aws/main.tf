################################################################################
# Network Infrastructure Resources
################################################################################
# Identify availability zones available for region selected
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}


################################################################################
# VPC
################################################################################
# Create a new VPC
resource "aws_vpc" "vpc" {
  count                = var.byo_vpc ? 0 : 1
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-vpc-${var.resource_tag}" }
  )
}

# Or reference an existing VPC
data "aws_vpc" "vpc_selected" {
  count = var.byo_vpc ? 1 : 0
  id    = var.byo_vpc_id
}


################################################################################
# Internet Gateway
################################################################################
# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  count  = var.byo_igw || var.exclude_igw ? 0 : 1
  vpc_id = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-igw-${var.resource_tag}" }
  )
}

# Or reference an existing Internet Gateway
data "aws_internet_gateway" "igw_selected" {
  count               = var.byo_igw ? 1 : 0
  internet_gateway_id = var.byo_igw_id
}


################################################################################
# NAT Gateway
################################################################################
# Create NAT Gateway and assign EIP per AZ. This will not be created if byo_ngw or exclude_ngw are true
resource "aws_eip" "eip" {
  count = var.byo_ngw || var.exclude_ngw ? 0 : length(aws_subnet.public_subnet[*].id)
  depends_on = [
    data.aws_internet_gateway.igw_selected,
    aws_internet_gateway.igw
  ]

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-eip-az${count.index + 1}-${var.resource_tag}" }
  )
}

# Create 1 NAT Gateway per Public Subnet. This resource will not create if no new Elastic IPs are created
resource "aws_nat_gateway" "ngw" {
  count         = length(aws_eip.eip[*].id)
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  depends_on = [
    data.aws_internet_gateway.igw_selected,
    aws_internet_gateway.igw
  ]

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-natgw-az${count.index + 1}-${var.resource_tag}" }
  )
}

# Or reference existing NAT Gateways
data "aws_nat_gateway" "ngw_selected" {
  count = var.byo_ngw ? length(var.byo_ngw_ids) : 0
  id    = element(var.byo_ngw_ids, count.index)
}


################################################################################
# Public (NAT Gateway) Subnet & Route Tables
################################################################################
# Create equal number of Public/NAT Subnets to how many Cloud Connector subnets exist. This will not be created if var.byo_ngw or var.exclude_igw is set to True
resource "aws_subnet" "public_subnet" {
  count                = var.byo_ngw ? 0 : length(local.zssubnetslist)
  availability_zone    = var.az_ids != null ? null : data.aws_availability_zones.available.names[count.index]
  availability_zone_id = var.az_ids != null ? element(var.az_ids, count.index) : null
  cidr_block           = var.public_subnets != null ? element(var.public_subnets, count.index) : cidrsubnet(try(data.aws_vpc.vpc_selected[0].cidr_block, aws_vpc.vpc[0].cidr_block), 8, count.index + 101)
  vpc_id               = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-public-subnet-${count.index + 1}-${var.resource_tag}" }
  )
}


# Create a public Route Table towards IGW. This will not be created if no public subnets are created
resource "aws_route_table" "public_rt" {
  count  = length(aws_subnet.public_subnet[*].id)
  vpc_id = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = try(data.aws_internet_gateway.igw_selected[0].internet_gateway_id, aws_internet_gateway.igw[0].id)
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-public-rt-${var.resource_tag}" }
  )
}


# Create equal number of Route Table associations to how many Public subnets exist. This will not be created if var.byo_ngw is set to True
resource "aws_route_table_association" "public_rt_association" {
  count          = length(aws_subnet.public_subnet[*].id)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt[0].id
}


################################################################################
# Private (Workload) Subnet & Route Tables
################################################################################
# Create equal number of Workload/Private Subnets to how many Cloud Connector subnets exist. This will not be created if var.workloads_enabled is set to False
resource "aws_subnet" "workload_subnet" {
  count                = var.workloads_enabled ? length(local.zssubnetslist) : 0
  availability_zone    = var.az_ids != null ? null : data.aws_availability_zones.available.names[count.index]
  availability_zone_id = var.az_ids != null ? element(var.az_ids, count.index) : null
  cidr_block           = var.workloads_subnets != null ? element(var.workloads_subnets, count.index) : cidrsubnet(try(data.aws_vpc.vpc_selected[0].cidr_block, aws_vpc.vpc[0].cidr_block), 8, count.index + 1)
  vpc_id               = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-workload-subnet-${count.index + 1}-${var.resource_tag}" }
  )
}

# Create Route Table for private subnets (workload servers) towards CC Service ENI or GWLB Endpoint depending on deployment type
resource "aws_route_table" "workload_rt" {
  count  = length(aws_subnet.workload_subnet[*].id)
  vpc_id = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)
  route {
    cidr_block           = "0.0.0.0/0"
    vpc_endpoint_id      = var.gwlb_enabled == true ? element(var.gwlb_endpoint_ids, count.index) : null
    network_interface_id = var.gwlb_enabled == false ? element(var.cc_service_enis, count.index) : null
    nat_gateway_id       = var.base_only == true ? try(element(data.aws_nat_gateway.ngw_selected[*].id, count.index), element(aws_nat_gateway.ngw[*].id, count.index)) : null
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-workload-to-cc-${count.index + 1}-rt-${var.resource_tag}" }
  )
}

# Create Workload Route Table Association
resource "aws_route_table_association" "workload_rt_association" {
  count          = length(aws_subnet.workload_subnet[*].id)
  subnet_id      = aws_subnet.workload_subnet[count.index].id
  route_table_id = aws_route_table.workload_rt[count.index].id
}


################################################################################
# Private (Cloud Connector/ZT Gateway) Subnet & Route Tables
################################################################################
# Create subnet for CC network in X availability zones per az_count variable. Do not create if byo_subnets is true
# For greenfield ZT Gateway deployments, ZT Endpoints will get deployed to this subnet instead 
resource "aws_subnet" "cc_subnet" {
  count                                       = var.byo_subnets ? 0 : local.createzssubnets
  availability_zone                           = var.az_ids != null ? null : data.aws_availability_zones.available.names[count.index]
  availability_zone_id                        = var.az_ids != null ? element(var.az_ids, count.index) : null
  cidr_block                                  = var.cc_subnets != null ? element(var.cc_subnets, count.index) : cidrsubnet(try(data.aws_vpc.vpc_selected[0].cidr_block, aws_vpc.vpc[0].cidr_block), 8, count.index + 200)
  vpc_id                                      = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)
  enable_resource_name_dns_a_record_on_launch = var.resource_name_dns_a_record_enabled
  private_dns_hostname_type_on_launch         = var.hostname_type

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-subnet-${count.index + 1}-${var.resource_tag}" }
  )
}

# Or reference existing subnets
data "aws_subnet" "cc_subnet_selected" {
  count = var.byo_subnets ? length(var.byo_subnet_ids) : 0
  id    = element(var.byo_subnet_ids, count.index)
}


# Create Route Tables for CC/ZT Gateway subnets pointing to NAT Gateway resource in each AZ or however many were specified
# For ZT Gateway deployments, if cc_route_table_enabled is true we will still create this route table for the ZT Endpoints
# and default route will show as itself. On the surface, this will look like a loop/blackhole but is not a problem
# Optionally, you could just set cc_route_table_enabled to false and not create any route table, but that goes against
# security best practices as the subnet would adopt the VPC default route table which may not be desired.
resource "aws_route_table" "cc_rt" {
  count  = var.cc_route_table_enabled ? length(local.zssubnetslist) : 0
  vpc_id = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)
  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = var.exclude_ngw ? null : try(element(data.aws_nat_gateway.ngw_selected[*].id, count.index), element(aws_nat_gateway.ngw[*].id, count.index))
    vpc_endpoint_id = var.exclude_ngw ? element(var.gwlb_endpoint_ids, count.index) : null
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-rt-${count.index + 1}-${var.resource_tag}" }
  )
}

# CC subnet Route Table Association
resource "aws_route_table_association" "cc_rt_asssociation" {
  count          = var.cc_route_table_enabled ? length(local.zssubnetslist) : 0
  subnet_id      = try(data.aws_subnet.cc_subnet_selected[count.index].id, aws_subnet.cc_subnet[count.index].id)
  route_table_id = aws_route_table.cc_rt[count.index].id
}


################################################################################
# Private (Route 53 Endpoint) Subnet & Route Tables
################################################################################
# Optional Route53 subnet creation for ZPA
# Create Route53 reserved subnets in X availability zones per az_count variable or minimum of 2; whichever is greater
resource "aws_subnet" "route53_subnet" {
  count                = var.zpa_enabled && length(var.byo_r53_subnet_ids) == 0 ? max(length(local.zssubnetslist), 2) : 0
  availability_zone    = var.az_ids != null ? null : data.aws_availability_zones.available.names[count.index]
  availability_zone_id = var.az_ids != null ? element(var.az_ids, count.index) : null
  cidr_block           = var.route53_subnets != null ? element(var.route53_subnets, count.index) : cidrsubnet(try(data.aws_vpc.vpc_selected[0].cidr_block, aws_vpc.vpc[0].cidr_block), 12, (64 + count.index * 16))
  vpc_id               = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-route53-subnet-${count.index + 1}-${var.resource_tag}" }
  )
}

# Or reference existing subnets
data "aws_subnet" "route53_subnet_selected" {
  count = var.zpa_enabled && length(var.byo_r53_subnet_ids) != 0 ? length(var.byo_r53_subnet_ids) : 0
  id    = element(var.byo_r53_subnet_ids, count.index)
}


# Create Route Table for Route53 routing to GWLB Endpoint in the same AZ for DNS redirection
resource "aws_route_table" "route53_rt" {
  count  = var.zpa_enabled && var.r53_route_table_enabled ? length(coalescelist(data.aws_subnet.route53_subnet_selected[*].id, aws_subnet.route53_subnet[*].id)) : 0
  vpc_id = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)
  route {
    cidr_block           = "0.0.0.0/0"
    vpc_endpoint_id      = var.gwlb_enabled == true ? element(var.gwlb_endpoint_ids, count.index) : null
    network_interface_id = var.gwlb_enabled == false ? element(var.cc_service_enis, count.index) : null
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-route53-to-cc-${count.index + 1}-rt-${var.resource_tag}" }
  )
}

# Route53 Subnets Route Table Assocation
resource "aws_route_table_association" "route53_rt_asssociation" {
  count          = length(aws_subnet.route53_subnet[*].id)
  subnet_id      = try(data.aws_subnet.route53_subnet_selected[count.index].id, aws_subnet.route53_subnet[count.index].id)
  route_table_id = aws_route_table.route53_rt[count.index].id
}
