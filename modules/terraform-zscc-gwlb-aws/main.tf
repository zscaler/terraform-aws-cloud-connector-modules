################################################################################
# Configure target group
################################################################################
resource "aws_lb_target_group" "gwlb_target_group" {
  name        = "${var.name_prefix}-cc-target-${var.resource_tag}"
  port        = 6081
  protocol    = "GENEVE"
  vpc_id      = var.vpc_id
  target_type = var.asg_enabled == true ? "instance" : "ip"

  health_check {
    port                = var.http_probe_port
    protocol            = "HTTP"
    path                = "/?cchealth"
    interval            = var.health_check_interval
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }
}


################################################################################
# Register all Small Cloud Connector Service Interface IPs as targets to gwlb. 
# This does not apply to "Medium" or "Large" Cloud Connector sizes
################################################################################
resource "aws_lb_target_group_attachment" "gwlb_target_group_attachment_small" {
  count            = var.cc_instance_size == "small" && var.asg_enabled == false ? length(var.cc_small_service_ips) : 0
  target_group_arn = aws_lb_target_group.gwlb_target_group.arn
  target_id        = element(var.cc_small_service_ips, count.index)

  depends_on = [var.cc_small_service_ips]
}


################################################################################
# Register all Medium/Large Cloud Connector Service Interface-1 IPs as targets 
# to gwlb. This does not apply to "Small" Cloud Connector sizes
################################################################################
resource "aws_lb_target_group_attachment" "gwlb_target_group_attachment_med_lrg_1" {
  count            = var.cc_instance_size != "small" && var.asg_enabled == false ? length(var.cc_med_lrg_service_1_ips) : 0
  target_group_arn = aws_lb_target_group.gwlb_target_group.arn
  target_id        = element(var.cc_med_lrg_service_1_ips, count.index)

  depends_on = [var.cc_med_lrg_service_1_ips]
}


################################################################################
# Register all Medium/Large Cloud Connector Service Interface-2 IPs as targets 
# to gwlb. This does not apply to "Small" Cloud Connector sizes
################################################################################
resource "aws_lb_target_group_attachment" "gwlb_target_group_attachment_med_lrg_2" {
  count            = var.cc_instance_size != "small" && var.asg_enabled == false ? length(var.cc_med_lrg_service_2_ips) : 0
  target_group_arn = aws_lb_target_group.gwlb_target_group.arn
  target_id        = element(var.cc_med_lrg_service_2_ips, count.index)

  depends_on = [var.cc_med_lrg_service_2_ips]
}


################################################################################
# Register all Large Cloud Connector Service Interface-3 IPs as targets to gwlb. 
# This does not apply to "Small" Cloud Connector sizes
################################################################################
resource "aws_lb_target_group_attachment" "gwlb_target_group_attachment_lrg_3" {
  count            = var.cc_instance_size == "large" && var.asg_enabled == false ? length(var.cc_lrg_service_3_ips) : 0
  target_group_arn = aws_lb_target_group.gwlb_target_group.arn
  target_id        = element(var.cc_lrg_service_3_ips, count.index)

  depends_on = [var.cc_lrg_service_3_ips]
}


################################################################################
# Configure the load balancer and listener
################################################################################
resource "aws_lb" "gwlb" {
  load_balancer_type               = "gateway"
  name                             = "${var.name_prefix}-cc-gwlb-${var.resource_tag}"
  enable_cross_zone_load_balancing = var.cross_zone_lb_enabled

  subnets = var.cc_subnet_ids

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-gwlb-${var.resource_tag}" }
  )
}

resource "aws_lb_listener" "gwlb_listener" {
  load_balancer_arn = aws_lb.gwlb.id

  default_action {
    target_group_arn = aws_lb_target_group.gwlb_target_group.id
    type             = "forward"
  }
}
