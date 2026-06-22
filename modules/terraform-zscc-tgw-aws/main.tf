################################################################################
# terraform-zscc-tgw-aws
#
# Encapsulates all Transit Gateway Hub-and-Spoke resources for Zscaler Cloud
# Connector centralized inspection deployments.
#
# TGW Route Table design:
#   spoke_rt : associated to Spoke 1 + Spoke 2 attachments
#              static route 0.0.0.0/0 → Hub attachment (all spoke egress → Hub)
#   hub_rt   : associated to Hub attachment
#              propagates spoke CIDRs from both spoke attachments (return path)
#
# VPC Route additions (Hub):
#   tgw_attach RT    : 0.0.0.0/0 → GWLB endpoint (one per AZ, steers ingress to CC)
#                      spoke_1_vpc_cidr → TGW  (return path Hub→Spoke 1)
#                      spoke_2_vpc_cidr → TGW  (return path Hub→Spoke 2)
#   gwlb_endpoint RT : spoke_1_vpc_cidr → TGW  (post-inspection return to Spoke 1)
#                      spoke_2_vpc_cidr → TGW  (post-inspection return to Spoke 2)
#                      (0.0.0.0/0 → NAT GW is pre-wired by terraform-zscc-network-aws)
################################################################################


################################################################################
# Transit Gateway
################################################################################
resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "${var.name_prefix}-hub-spoke-tgw-${var.resource_tag}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = merge(var.global_tags, {
    Name = "${var.tgw_name}-${var.resource_tag}"
  })
}


################################################################################
# TGW VPC Attachments — Hub + Spoke 1 + Spoke 2
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.hub_vpc_id
  subnet_ids         = var.hub_tgw_attach_subnet_ids

  # appliance_mode_support is required for GWLB-based inspection.
  # Without it, TGW may route return traffic through a different AZ ENI than
  # the one the original flow arrived on, breaking GWLB's 5-tuple flow stickiness
  # and causing traffic to bypass the Cloud Connector.
  appliance_mode_support = "enable"

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-hub-${var.resource_tag}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_1" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.spoke_1_vpc_id
  subnet_ids         = var.spoke_1_workload_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-spoke-1-${var.resource_tag}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_2" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.spoke_2_vpc_id
  subnet_ids         = var.spoke_2_workload_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-attach-spoke-2-${var.resource_tag}"
  })
}


################################################################################
# TGW Route Tables
################################################################################
resource "aws_ec2_transit_gateway_route_table" "spoke_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-spoke-rt-${var.resource_tag}"
  })
}

resource "aws_ec2_transit_gateway_route_table" "hub_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = merge(var.global_tags, {
    Name = "${var.name_prefix}-tgw-hub-rt-${var.resource_tag}"
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
# VPC Routes — Hub TGW attach subnet RTs
#
# 0.0.0.0/0 → GWLB endpoint (per AZ): steers spoke ingress to CC for inspection.
# spoke CIDRs → TGW: ensures Hub-originated return traffic reaches the spokes.
################################################################################
resource "aws_route" "hub_tgw_attach_to_gwlbe" {
  count                  = var.az_count
  route_table_id         = var.hub_tgw_attach_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = var.gwlb_endpoint_ids[count.index]

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_tgw_attach_to_spoke_1" {
  count                  = var.az_count
  route_table_id         = var.hub_tgw_attach_route_table_ids[count.index]
  destination_cidr_block = var.spoke_1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_tgw_attach_to_spoke_2" {
  count                  = var.az_count
  route_table_id         = var.hub_tgw_attach_route_table_ids[count.index]
  destination_cidr_block = var.spoke_2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}


################################################################################
# VPC Routes — Hub GWLB endpoint subnet RTs
#
# After CC returns inspected traffic through the GWLB Endpoint, response packets
# destined for spoke private IPs must be routed back via TGW.
# The 0.0.0.0/0 → NAT GW route is pre-wired in terraform-zscc-network-aws.
################################################################################
resource "aws_route" "hub_gwlb_endpoint_to_spoke_1" {
  count                  = var.az_count
  route_table_id         = var.hub_gwlb_endpoint_route_table_ids[count.index]
  destination_cidr_block = var.spoke_1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_gwlb_endpoint_to_spoke_2" {
  count                  = var.az_count
  route_table_id         = var.hub_gwlb_endpoint_route_table_ids[count.index]
  destination_cidr_block = var.spoke_2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}
