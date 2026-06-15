################################################################################
# Network Infrastructure Resources
################################################################################
# Identify availability zones available for region selected
data "aws_availability_zones" "available" {
  state = "available"
}


################################################################################
# VPC
################################################################################
# Create a new VPC
resource "aws_vpc" "vpc" {
  count                = var.byo_vpc == false ? 1 : 0
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
  count  = var.byo_igw == false ? 1 : 0
  vpc_id = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-igw-${var.resource_tag}" }
  )
}

# Or reference an existing Internet Gateway
data "aws_internet_gateway" "igw_selected" {
  internet_gateway_id = var.byo_igw == false ? aws_internet_gateway.igw[0].id : var.byo_igw_id
}


################################################################################
# Public (NAT Gateway) Subnet & Route Tables
################################################################################
# Create equal number of Public/NAT Subnets to how many Cloud Connector subnets exist. This will not be created if var.byo_ngw is set to True
resource "aws_subnet" "public_subnet" {
  count             = var.byo_ngw == false ? var.az_count : 0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.public_subnets != null ? element(var.public_subnets, count.index) : cidrsubnet(try(data.aws_vpc.vpc_selected[0].cidr_block, aws_vpc.vpc[0].cidr_block), 8, count.index + 101)
  vpc_id            = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-public-subnet-${count.index + 1}-${var.resource_tag}" }
  )
}


# Create a public Route Table towards IGW. This will not be created if var.byo_ngw is set to True
resource "aws_route_table" "public_rt" {
  count  = var.byo_ngw == false ? 1 : 0
  vpc_id = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.igw_selected.internet_gateway_id
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-public-rt-${var.resource_tag}" }
  )
}


# Create equal number of Route Table associations to how many Public subnets exist. This will not be created if var.byo_ngw is set to True
resource "aws_route_table_association" "public_rt_association" {
  count          = var.byo_ngw == false ? length(aws_subnet.public_subnet[*].id) : 0
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt[0].id
}


################################################################################
# Private (Workload) Subnet & Route Tables
################################################################################
# Create equal number of Workload/Private Subnets to how many Cloud Connector subnets exist. This will not be created if var.workloads_enabled is set to False
resource "aws_subnet" "workload_subnet" {
  count             = var.workloads_enabled == true ? var.az_count : 0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.workloads_subnets != null ? element(var.workloads_subnets, count.index) : cidrsubnet(try(data.aws_vpc.vpc_selected[0].cidr_block, aws_vpc.vpc[0].cidr_block), 8, count.index + 1)
  vpc_id            = try(data.aws_vpc.vpc_selected[0].id, aws_vpc.vpc[0].id)

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
