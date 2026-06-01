################################################################################
# Transit Gateway — shared between Hub VPC and both Spoke VPCs
#
# One TGW with two custom route tables:
#   spoke_rt : associated to Spoke 1 + Spoke 2 attachments
#              static route 0.0.0.0/0 → Hub attachment (all spoke egress → Hub)
#   hub_rt   : associated to Hub attachment
#              propagates spoke CIDR routes back from both spoke attachments
################################################################################

resource "aws_ec2_transit_gateway" "tgw" {
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
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.hub.id
  subnet_ids         = aws_subnet.hub_tgw_attach[*].id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-hub-${random_string.suffix.result}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_1" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.spoke_1.id
  subnet_ids         = aws_subnet.spoke_1_workload[*].id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-spoke-1-${random_string.suffix.result}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_2" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.spoke_2.id
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

# Spoke RT — associated to both spoke attachments; default route → Hub
resource "aws_ec2_transit_gateway_route_table" "spoke_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-spoke-rt-${random_string.suffix.result}"
  })
}

# Hub RT — associated to hub attachment; receives propagated spoke routes
resource "aws_ec2_transit_gateway_route_table" "hub_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = merge(local.global_tags, {
    Name = "${var.name_prefix}-tgw-hub-rt-${random_string.suffix.result}"
  })
}


################################################################################
# TGW Route Table Associations
################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "spoke_1_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_2_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "hub_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}


################################################################################
# TGW Routes
# Spoke RT: static default route → Hub attachment (all spoke traffic → Hub VPC)
################################################################################
resource "aws_ec2_transit_gateway_route" "spoke_default_to_hub" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}


################################################################################
# TGW Route Table Propagations
# Hub RT: propagate each spoke's CIDR so Hub knows how to return traffic to spokes
################################################################################
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_1_to_hub_rt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_2_to_hub_rt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}


################################################################################
# VPC Route — Hub TGW attach subnet back to spokes (for any return path via TGW)
# Spoke 1 CIDR and Spoke 2 CIDR → TGW (from Hub VPC TGW attach subnet RT)
################################################################################
resource "aws_route" "hub_tgw_attach_to_spoke_1" {
  count                  = var.az_count
  route_table_id         = aws_route_table.hub_tgw_attach_rt[count.index].id
  destination_cidr_block = var.spoke_1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_tgw_attach_to_spoke_2" {
  count                  = var.az_count
  route_table_id         = aws_route_table.hub_tgw_attach_rt[count.index].id
  destination_cidr_block = var.spoke_2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}


################################################################################
# VPC Route — Hub GWLB endpoint subnet back to spokes via TGW
#
# BUG FIX: After CC returns inspected traffic through the GWLB Endpoint, the
# response packet is destined for a spoke private IP (e.g. 10.1.x.x / 10.2.x.x).
# Without these routes the hub_gwlb_endpoint_rt only has 0.0.0.0/0 → NAT GW,
# so response packets are black-holed / sent to NAT instead of back to the spoke.
# Adding spoke CIDR → TGW here closes the return path:
#   CC → GWLB → GWLB Endpoint subnet → TGW → Spoke workload
################################################################################
resource "aws_route" "hub_gwlb_endpoint_to_spoke_1" {
  count                  = var.az_count
  route_table_id         = aws_route_table.hub_gwlb_endpoint_rt[count.index].id
  destination_cidr_block = var.spoke_1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_gwlb_endpoint_to_spoke_2" {
  count                  = var.az_count
  route_table_id         = aws_route_table.hub_gwlb_endpoint_rt[count.index].id
  destination_cidr_block = var.spoke_2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}
