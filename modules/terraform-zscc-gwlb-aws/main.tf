################################################################################
# Configure target group
################################################################################
resource "aws_lb_target_group" "gwlb_target_group" {
  name                 = var.target_group_name
  port                 = 6081
  protocol             = "GENEVE"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    port                = var.http_probe_port
    protocol            = "HTTP"
    path                = "/?cchealth"
    interval            = var.health_check_interval
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }

  target_failover {
    on_deregistration = var.rebalance_enabled == true ? "rebalance" : "no_rebalance"
    on_unhealthy      = var.rebalance_enabled == true ? "rebalance" : "no_rebalance"
  }

  # type attribute only applies if enabled = true and only options are "source_ip_dest_ip" (2-tuple) or "source_ip_dest_ip_proto" (3-tuple).
  # enabled = false implies 5-tuple. AWS gives type a default value of "source_ip_dest_ip_proto" even if enabled is set to false
  stickiness {
    enabled = var.flow_stickiness == "5-tuple" ? false : true
    type    = var.flow_stickiness == "2-tuple" ? "source_ip_dest_ip" : "source_ip_dest_ip_proto"
  }
}


################################################################################
# Register all Cloud Connector Forwarding Service Interface IPs as targets to gwlb
################################################################################
resource "aws_lb_target_group_attachment" "gwlb_target_group_attachment" {
  count            = length(var.cc_service_ips)
  target_group_arn = aws_lb_target_group.gwlb_target_group.arn
  target_id        = element(var.cc_service_ips, count.index)
}


################################################################################
# Configure the load balancer and listener
################################################################################
resource "aws_lb" "gwlb" {
  load_balancer_type               = "gateway"
  name                             = var.gwlb_name
  enable_cross_zone_load_balancing = var.cross_zone_lb_enabled

  subnets = var.cc_subnet_ids

  tags = merge(var.global_tags,
    { Name = var.gwlb_name }
  )
}

resource "aws_lb_listener" "gwlb_listener" {
  load_balancer_arn = aws_lb.gwlb.id

  default_action {
    target_group_arn = aws_lb_target_group.gwlb_target_group.id
    type             = "forward"
  }
}
