################################################################################
# Availability Zones — used for spoke subnet AZ assignment in TGW mode
################################################################################
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}


################################################################################
# Transit Gateway — Hub-and-Spoke centralized inspection
#
# All resources in this file are created only when tgw_enabled = true.
#
# TGW Route Table design:
#   spoke_rt : associated to Spoke 1 + Spoke 2 attachments
#              static route 0.0.0.0/0 → Hub attachment (all spoke egress → Hub)
#   hub_rt   : associated to Hub attachment
#              propagates spoke CIDRs from both spoke attachments (return path)
#
# VPC Route additions (Hub):
#   tgw_attach RT  : 0.0.0.0/0 → GWLB endpoint (one per AZ)
#                    spoke CIDRs → TGW (for any Hub→Spoke return via TGW)
#   gwlb_endpoint RT: spoke CIDRs → TGW (return path after NAT)
#                     (0.0.0.0/0 → NAT GW is pre-wired in the network module)
################################################################################


################################################################################
# Transit Gateway
################################################################################
resource "aws_ec2_transit_gateway" "tgw" {
  count                           = var.tgw_enabled ? 1 : 0
  description                     = "${var.name_prefix}-hub-spoke-tgw-${random_string.suffix.result}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = merge(local.global_tags, {
    Name = "${var.tgw_name}-${random_string.suffix.result}"
  })
}


################################################################################
# TGW VPC Attachments — Hub + Spoke 1 + Spoke 2
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  count              = var.tgw_enabled ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.tgw[0].id
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.tgw_attach_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-hub-${random_string.suffix.result}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_1" {
  count              = var.tgw_enabled ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.tgw[0].id
  vpc_id             = aws_vpc.spoke_1[0].id
  subnet_ids         = aws_subnet.spoke_1_workload[*].id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-spoke-1-${random_string.suffix.result}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_2" {
  count              = var.tgw_enabled ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.tgw[0].id
  vpc_id             = aws_vpc.spoke_2[0].id
  subnet_ids         = aws_subnet.spoke_2_workload[*].id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-spoke-2-${random_string.suffix.result}"
  })
}


################################################################################
# TGW Route Tables
################################################################################
resource "aws_ec2_transit_gateway_route_table" "spoke_rt" {
  count              = var.tgw_enabled ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.tgw[0].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-spoke-rt-${random_string.suffix.result}"
  })
}

resource "aws_ec2_transit_gateway_route_table" "hub_rt" {
  count              = var.tgw_enabled ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.tgw[0].id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-hub-rt-${random_string.suffix.result}"
  })
}


################################################################################
# TGW Route Table Associations
################################################################################
resource "aws_ec2_transit_gateway_route_table_association" "spoke_1_assoc" {
  count                          = var.tgw_enabled ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt[0].id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_2_assoc" {
  count                          = var.tgw_enabled ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt[0].id
}

resource "aws_ec2_transit_gateway_route_table_association" "hub_assoc" {
  count                          = var.tgw_enabled ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt[0].id
}


################################################################################
# TGW Routes
# Spoke RT: static default route → Hub attachment (all spoke traffic → Hub VPC)
################################################################################
resource "aws_ec2_transit_gateway_route" "spoke_default_to_hub" {
  count                          = var.tgw_enabled ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt[0].id
}


################################################################################
# TGW Route Table Propagations
# Hub RT: propagate each spoke's CIDR so Hub knows how to return traffic to spokes
################################################################################
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_1_to_hub_rt" {
  count                          = var.tgw_enabled ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_2_to_hub_rt" {
  count                          = var.tgw_enabled ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt[0].id
}


################################################################################
# VPC Routes — Hub TGW attach subnet RT
#
# 0.0.0.0/0 → GWLB endpoint (per AZ): steers spoke ingress to CC for inspection.
# spoke CIDRs → TGW: ensures any Hub-originated return traffic reaches the spokes.
################################################################################
resource "aws_route" "hub_tgw_attach_to_gwlbe" {
  count                  = var.tgw_enabled ? var.az_count : 0
  route_table_id         = module.network.tgw_attach_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = module.gwlb_endpoint.gwlbe[count.index]

  depends_on = [module.gwlb_endpoint]
}

resource "aws_route" "hub_tgw_attach_to_spoke_1" {
  count                  = var.tgw_enabled ? var.az_count : 0
  route_table_id         = module.network.tgw_attach_route_table_ids[count.index]
  destination_cidr_block = var.spoke_1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw[0].id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_tgw_attach_to_spoke_2" {
  count                  = var.tgw_enabled ? var.az_count : 0
  route_table_id         = module.network.tgw_attach_route_table_ids[count.index]
  destination_cidr_block = var.spoke_2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw[0].id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}


################################################################################
# VPC Routes — Hub GWLB endpoint subnet RT
#
# After CC returns inspected traffic through the GWLB Endpoint, response packets
# destined for spoke private IPs must be routed back via TGW.
# The 0.0.0.0/0 → NAT GW route is pre-wired in the network module.
################################################################################
resource "aws_route" "hub_gwlb_endpoint_to_spoke_1" {
  count                  = var.tgw_enabled ? var.az_count : 0
  route_table_id         = module.network.gwlb_endpoint_route_table_ids[count.index]
  destination_cidr_block = var.spoke_1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw[0].id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_gwlb_endpoint_to_spoke_2" {
  count                  = var.tgw_enabled ? var.az_count : 0
  route_table_id         = module.network.gwlb_endpoint_route_table_ids[count.index]
  destination_cidr_block = var.spoke_2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw[0].id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}
