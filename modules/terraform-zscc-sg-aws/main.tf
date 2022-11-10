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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-mgmt-sg-${var.resource_tag}" }
  )
}

# Or use existing Management Security Group ID
data "aws_security_group" "cc_mgmt_sg_selected" {
  count = var.byo_security_group == false ? length(aws_security_group.cc_mgmt_sg[*].id) : length(var.byo_mgmt_security_group_id)
  id    = var.byo_security_group == false ? element(aws_security_group.cc_mgmt_sg[*].id, count.index) : element(var.byo_mgmt_security_group_id, count.index)
}

resource "aws_security_group_rule" "cc_mgmt_ingress_ssh" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Allow SSH to Cloud Connector VM"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-svc-sg-${var.resource_tag}" }
  )
}

# Or use existing Service Security Group ID
data "aws_security_group" "cc_service_sg_selected" {
  count = var.byo_security_group == false ? length(aws_security_group.cc_service_sg[*].id) : length(var.byo_service_security_group_id)
  id    = var.byo_security_group == false ? element(aws_security_group.cc_service_sg[*].id, count.index) : element(var.byo_service_security_group_id, count.index)
}

resource "aws_security_group_rule" "all_vpc_ingress_cc" {
  count             = var.byo_security_group == false ? var.sg_count : 0
  description       = "Allow all VPC traffic"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.cc_service_sg[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}
