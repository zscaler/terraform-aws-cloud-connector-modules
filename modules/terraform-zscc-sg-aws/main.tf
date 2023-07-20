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

  egress {
    description = "Required: CC Management outbound TCP/443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Permit CC mgmt egress UDP 123"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Recommended: Default allow CC egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-mgmt-sg-${var.resource_tag}" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Or use existing Management Security Group ID
data "aws_security_group" "cc_mgmt_sg_selected" {
  count = var.byo_security_group ? length(var.byo_mgmt_security_group_id) : 0
  id    = element(var.byo_mgmt_security_group_id, count.index)
}

################################################################################
# Create ingress rule for Management SSH access
################################################################################
resource "aws_security_group_rule" "cc_mgmt_ingress_ssh" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Recommended: Allow SSH to Cloud Connector VM"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.cc_mgmt_sg[count.index].id
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  type              = "ingress"
}


################################################################################
# Create Security Group and Rules for Cloud Connector Service Interfaces
################################################################################
resource "aws_security_group" "cc_service_sg" {
  count       = var.byo_security_group == false ? var.sg_count : 0
  name        = var.sg_count > 1 ? "${var.name_prefix}-cc-${count.index + 1}-svc-sg-${var.resource_tag}" : "${var.name_prefix}-cc-svc-sg-${var.resource_tag}"
  description = "Security group for Cloud Connector service interfaces"
  vpc_id      = var.vpc_id

  ingress {
    description = "Required: Permit ingress GENEVE encapsulation traffic from GWLB to CC Service"
    from_port   = 6081
    to_port     = 6081
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
  egress {
    description = "Required: CC Service outbound TCP/443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Required: CC Service outbound UDP/443"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Permit CC Service egress UDP 123"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Required: Permit CC Service egress GENEVE encapsulation traffic to GWLB"
    from_port   = 6081
    to_port     = 6081
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
  egress {
    description = "Recommended: Default allow CC egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-svc-sg-${var.resource_tag}" }
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

################################################################################
# Create ingress rule for all traffic catch-all - Required if workloads
# sending all ports and protocols
################################################################################
resource "aws_security_group_rule" "all_vpc_ingress_cc" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Permit all workload traffic initiated traffic"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_blocks       = var.default_security_group
  type              = "ingress"
}
