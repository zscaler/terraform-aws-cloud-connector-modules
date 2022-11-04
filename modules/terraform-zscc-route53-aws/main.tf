################################################################################
# Pull in default security group information
################################################################################
data "aws_security_group" "selected" {
  vpc_id = var.vpc_id
  name   = "default"
}


################################################################################
# Create Route 53 outbound endpoints per subnet IDs specified
################################################################################
resource "aws_route53_resolver_endpoint" "zpa_r53_ep" {
  name      = "${var.name_prefix}-r53-resolver-ep-${var.resource_tag}"
  direction = "OUTBOUND"

  security_group_ids = [
    data.aws_security_group.selected.id
  ]

  dynamic "ip_address" {
    for_each = var.r53_subnet_ids
    iterator = subnet_id

    content {
      subnet_id = subnet_id.value
    }
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-r53-resolver-ep-${var.resource_tag}" }
  )
}


################################################################################
# Create Route 53 resolver rule to steer ZPA desired domain requests to 
# Cloud Connector per map for variable "domain_names"
################################################################################
resource "aws_route53_resolver_rule" "fwd_to_cc" {
  for_each             = var.domain_names
  domain_name          = each.value
  name                 = "${var.name_prefix}-r53-rule-${each.key}-${var.resource_tag}"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.zpa_r53_ep.id

  dynamic "target_ip" {
    for_each = var.target_address

    content {
      ip = target_ip.value
    }
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-r53-rules-${each.key}-${var.resource_tag}" }
  )
}

# Associate Route 53 Forward Resolver rules to VPC
resource "aws_route53_resolver_rule_association" "r53_rule_association_to_cc" {
  for_each         = var.domain_names
  resolver_rule_id = aws_route53_resolver_rule.fwd_to_cc[each.key].id
  vpc_id           = var.vpc_id
}


################################################################################
# Create Route 53 resolver rules to have AWS recursively resolve Zscaler 
# domains directly rather than send to Cloud Connector
################################################################################
resource "aws_route53_resolver_rule" "system" {
  for_each    = var.zscaler_domains
  domain_name = each.value
  name        = "${var.name_prefix}-r53-system-rule-${each.key}-${var.resource_tag}"
  rule_type   = "SYSTEM"

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-r53-rules-${each.key}-${var.resource_tag}" }
  )
}

# Associate Route 53 System Resolver rules to VPC
resource "aws_route53_resolver_rule_association" "r53_rule_association_system" {
  for_each         = var.zscaler_domains
  resolver_rule_id = aws_route53_resolver_rule.system[each.key].id
  vpc_id           = var.vpc_id
}
