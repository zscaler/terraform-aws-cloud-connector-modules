################################################################################
# Pull in VPC info
################################################################################
data "aws_vpc" "selected" {
  id = var.vpc_id
}


################################################################################
# Create Security Group and Rules for Cloud Connector Management Interfaces
################################################################################
resource "aws_security_group" "cc_mgmt_sg" {
  count       = var.byo_security_group == false ? var.sg_count : 0
  name        = var.sg_count > 1 ? "${var.name_prefix}-cc-${count.index + 1}-mgmt-sg-${var.resource_tag}" : "${var.name_prefix}-cc-mgmt-sg-${var.resource_tag}"
  description = "Security group for Cloud Connector management interface"
  vpc_id      = var.vpc_id

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-mgmt-sg-${count.index + 1}-${var.resource_tag}" }
  )

  lifecycle {
    create_before_destroy = true
  }
}



#Recommended ingress connectivity. If var.mgmt_ssh_enabled is set to false, the only way to access this VM would be SSM
resource "aws_vpc_security_group_ingress_rule" "cc_mgmt_ingress_ssh" {
  count             = var.mgmt_ssh_enabled && var.byo_security_group == false ? var.sg_count : 0
  description       = "Recommended: SSH to CC management"
  security_group_id = aws_security_group.cc_mgmt_sg[count.index].id
  cidr_ipv4         = data.aws_vpc.selected.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

#Default required egress connectivity
resource "aws_vpc_security_group_egress_rule" "egress_cc_mgmt_tcp_443" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Required: CC outbound TCP 443"
  security_group_id = aws_security_group.cc_mgmt_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "egress_cc_mgmt_udp_123" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Required: CC Mgmt outbound NTP"
  security_group_id = aws_security_group.cc_mgmt_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 123
  ip_protocol       = "udp"
  to_port           = 123
}

resource "aws_vpc_security_group_egress_rule" "egress_cc_mgmt_pkg_repo" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Required: CC Mgmt outbound Zscaler Repo Server"
  security_group_id = aws_security_group.cc_mgmt_sg[count.index].id
  cidr_ipv4         = "167.103.95.222/32"
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}

resource "aws_vpc_security_group_egress_rule" "egress_cc_mgmt_udp_53" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Recommended: CC Mgmt outbound DNS"
  security_group_id = aws_security_group.cc_mgmt_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  ip_protocol       = "udp"
  to_port           = 53
}


resource "aws_vpc_security_group_egress_rule" "egress_cc_mgmt_tcp_12002" {
  count             = var.byo_security_group == false && var.support_access_enabled == true ? var.sg_count : 0
  description       = "Recommended: CC Mgmt outbound Zscaler Remote Support TCP/12002"
  security_group_id = aws_security_group.cc_mgmt_sg[count.index].id
  cidr_ipv4         = var.zssupport_server
  from_port         = 12002
  ip_protocol       = "tcp"
  to_port           = 12002
}

# Or use existing Management Security Group ID
data "aws_security_group" "cc_mgmt_sg_selected" {
  count = var.byo_security_group ? length(var.byo_mgmt_security_group_id) : 0
  id    = element(var.byo_mgmt_security_group_id, count.index)
}


################################################################################
# Create Security Group and Rules for Cloud Connector Service Interfaces
################################################################################
resource "aws_security_group" "cc_service_sg" {
  count       = var.byo_security_group == false ? var.sg_count : 0
  name        = var.sg_count > 1 ? "${var.name_prefix}-cc-${count.index + 1}-svc-sg-${var.resource_tag}" : "${var.name_prefix}-cc-svc-sg-${var.resource_tag}"
  description = "Security group for Cloud Connector service interfaces"
  vpc_id      = var.vpc_id

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-svc-sg-${count.index + 1}-${var.resource_tag}" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Or use existing Service Security Group ID
data "aws_security_group" "cc_service_sg_selected" {
  count = var.byo_security_group ? length(var.byo_service_security_group_id) : 0
  id    = element(var.byo_service_security_group_id, count.index)
}


#Default required ingress connectivity
resource "aws_vpc_security_group_ingress_rule" "ingress_cc_service_health_check" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Required: CC Service TCP health probe"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = data.aws_vpc.selected.cidr_block
  from_port         = var.http_probe_port
  ip_protocol       = "tcp"
  to_port           = var.http_probe_port
}

resource "aws_vpc_security_group_ingress_rule" "ingress_cc_service_https_local" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Required: CC inbound internal VPC cluster TCP 443 communication"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = data.aws_vpc.selected.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

#Default required egress connectivity
resource "aws_vpc_security_group_egress_rule" "egress_cc_service_tcp_443" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Required: CC outbound TCP 443"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "egress_cc_service_udp_443" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Required: CC Service outbound UDP 443"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "udp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "egress_cc_service_udp_123" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Required: CC Service outbound NTP"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 123
  ip_protocol       = "udp"
  to_port           = 123
}

resource "aws_vpc_security_group_egress_rule" "egress_cc_service_udp_53" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Recommended: CC Service outbound DNS"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  ip_protocol       = "udp"
  to_port           = 53
}

#Default required for GWLB deployments
resource "aws_vpc_security_group_ingress_rule" "ingress_cc_service_geneve" {
  count             = var.byo_security_group == false && var.gwlb_enabled ? var.sg_count : 0
  description       = "Required: CC GENEVE encapsulation traffic to CC Service from GWLB"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = data.aws_vpc.selected.cidr_block
  from_port         = 6081
  ip_protocol       = "udp"
  to_port           = 6081
}

resource "aws_vpc_security_group_egress_rule" "egress_cc_service_geneve" {
  count             = var.byo_security_group == false && var.gwlb_enabled ? var.sg_count : 0
  description       = "Required: CC GENEVE encapsulation traffic to GWLB from CC Service"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = data.aws_vpc.selected.cidr_block
  from_port         = 6081
  ip_protocol       = "udp"
  to_port           = 6081
}


#Default required for non-GWLB deployments
resource "aws_vpc_security_group_ingress_rule" "ingress_cc_service_all" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Optional: Permit All Intra-VPC Traffic / Ensure CC Service Interfaces are able to communicate with each other freely"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = data.aws_vpc.selected.cidr_block
  ip_protocol       = "-1"
}

#Default recommended egress connectivity. *Only required if sending direct/bypass non-https traffic through Cloud Connector
resource "aws_vpc_security_group_egress_rule" "egress_cc_service_all" {
  count             = var.byo_security_group == false && var.all_ports_egress_enabled ? var.sg_count : 0
  description       = "Optional: CC outbound all ports and protocols"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


################################################################################
# Create Security Group and Rules for Route53 DNS Resolver Outbound Endpoint
################################################################################
resource "aws_security_group" "outbound_endpoint_sg" {
  # Only create outbound endpoint security group if zpa is enabled
  count       = var.zpa_enabled && var.byo_security_group == false ? 1 : 0
  name        = "${var.name_prefix}-outbound-dns-endpoint-sg-${var.resource_tag}"
  description = "Security group for Route53 DNS Resolver Outbound Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-outbound-dns-endpoint-sg-${var.resource_tag}" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Or use existing Route53 DNS Resolver Outbound Endpoint Security Group ID
data "aws_security_group" "outbound_endpoint_sg_selected" {
  # Only look for an existing outbound endpoint security group if byo_security_group is true AND zpa is enabled
  count = var.zpa_enabled && var.byo_security_group ? length(var.byo_route53_resolver_outbound_endpoint_group_id) : 0
  id    = element(var.byo_route53_resolver_outbound_endpoint_group_id, count.index)
}


#Default required ingress connectivity
# https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/best-practices-resolver-endpoint-scaling.html
resource "aws_vpc_security_group_ingress_rule" "ingress_outbound_endpoint_tcp_all" {
  count             = var.zpa_enabled == true && var.byo_security_group == false ? 1 : 0
  description       = "Required: Resolver TCP Ingress"
  security_group_id = aws_security_group.outbound_endpoint_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}

resource "aws_vpc_security_group_ingress_rule" "ingress_outbound_endpoint_udp_all" {
  count             = var.zpa_enabled == true && var.byo_security_group == false ? 1 : 0
  description       = "Required: Resolver UDP Ingress"
  security_group_id = aws_security_group.outbound_endpoint_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  ip_protocol       = "udp"
  to_port           = 65535
}

#Default required egress connectivity
resource "aws_vpc_security_group_egress_rule" "egress_outbound_endpoint_tcp_all" {
  count             = var.zpa_enabled == true && var.byo_security_group == false ? 1 : 0
  description       = "Required: Resolver TCP Egress"
  security_group_id = aws_security_group.outbound_endpoint_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}

resource "aws_vpc_security_group_egress_rule" "egress_outbound_endpoint_udp_all" {
  count             = var.zpa_enabled == true && var.byo_security_group == false ? 1 : 0
  description       = "Required: Resolver UDP Egress"
  security_group_id = aws_security_group.outbound_endpoint_sg[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  ip_protocol       = "udp"
  to_port           = 65535
}
