################################################################################
# Module VM creation validation
################################################################################
resource "null_resource" "error_checker" {
  count = local.valid_cc_create ? 0 : 1 # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> ${path.root}/errorlog.txt
EOF
  }
}


################################################################################
# Create launch template for Cloud Connector autoscaling group instance creation. 
# Mgmt and service interface device indexes are swapped to support ASG + GWLB 
# instance association
################################################################################
resource "aws_launch_template" "cc_launch_template" {
  count         = local.valid_cc_create && var.cc_instance_size == "small" ? 1 : 0
  name          = "${var.name_prefix}-cc-launch-template-${var.resource_tag}"
  image_id      = var.ami_id[0]
  instance_type = var.ccvm_instance_type
  key_name      = var.instance_key
  user_data     = base64encode(var.user_data)

  iam_instance_profile {
    name = element(var.iam_instance_profile, count.index)
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.global_tags, { Name = "${var.name_prefix}-ccvm-asg-${var.resource_tag}" })
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = merge(var.global_tags, { Name = "${var.name_prefix}-ccvm-nic-asg-${var.resource_tag}" })
  }

  network_interfaces {
    description                 = "Interface for service traffic"
    device_index                = 0
    security_groups             = [element(var.service_security_group_id, count.index)]
    associate_public_ip_address = false
  }

  network_interfaces {
    description                 = "Interface for management traffic"
    device_index                = 1
    security_groups             = [element(var.mgmt_security_group_id, 0)]
    associate_public_ip_address = false
  }

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  tags = merge(var.global_tags)

  lifecycle {
    create_before_destroy = true
  }
}


################################################################################
# Create Cloud Connector autoscaling group per AZ
################################################################################
resource "aws_autoscaling_group" "cc_asg" {
  count                     = length(var.cc_subnet_ids)
  name                      = "${var.name_prefix}-cc-asg-${var.resource_tag}"
  vpc_zone_identifier       = element(distinct(var.cc_subnet_ids), count.index)
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_instance_warmup   = var.instance_warmup
  protect_from_scale_in     = var.protect_from_scale_in

  launch_template {
    id      = aws_launch_template.cc_launch_template[0].id
    version = var.launch_template_version
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  dynamic "warm_pool" {
    for_each = var.warm_pool_enabled == true ? [var.warm_pool_enabled] : []
    content {
      pool_state                  = var.warm_pool_state
      min_size                    = var.warm_pool_min_size
      max_group_prepared_capacity = var.warm_pool_max_group_prepared_capacity
      instance_reuse_policy {
        reuse_on_scale_in = var.reuse_on_scale_in
      }
    }
  }

  dynamic "tag" {
    for_each = var.global_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [load_balancers, desired_capacity, target_group_arns]
  }
}


################################################################################
# Automatically associate all Cloud Connector instances created by autoscaling 
# group to GWLB Target Group
################################################################################
resource "aws_autoscaling_attachment" "cc_asg_attachment_gwlb" {
  count                  = length(aws_autoscaling_group.cc_asg[*].id)
  autoscaling_group_name = aws_autoscaling_group.cc_asg[count.index].id
  lb_target_group_arn    = var.target_group_arn
}


################################################################################
# Create autoscaling group policy based on dynamic Target Tracking Scaling on 
# average CPU
################################################################################
resource "aws_autoscaling_policy" "cc_asg_target_tracking_policy" {
  count                  = length(aws_autoscaling_group.cc_asg[*].id)
  name                   = "${var.name_prefix}-cc-asg-target-policy-${count.index + 1}-${var.resource_tag}"
  autoscaling_group_name = aws_autoscaling_group.cc_asg[count.index].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.target_tracking_metric
    }
    target_value = var.target_cpu_util_value
  }
}


################################################################################
# Create autoscaling lifecycle hooks for instance launch and terminate
################################################################################
resource "aws_autoscaling_lifecycle_hook" "cc_asg_lifecyclehook_launch" {
  count                  = length(aws_autoscaling_group.cc_asg[*].id)
  name                   = "${var.name_prefix}-cc-asg-lifecyclehook-launch-${count.index + 1}-${var.resource_tag}"
  autoscaling_group_name = aws_autoscaling_group.cc_asg[count.index].name
  default_result         = "ABANDON"
  heartbeat_timeout      = var.lifecyclehook_instance_launch_wait_time
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

resource "aws_autoscaling_lifecycle_hook" "cc_asg_lifecyclehook_terminate" {
  count                  = length(aws_autoscaling_group.cc_asg[*].id)
  name                   = "${var.name_prefix}-cc-asg-lifecyclehook-terminate-${count.index + 1}-${var.resource_tag}"
  autoscaling_group_name = aws_autoscaling_group.cc_asg[count.index].name
  default_result         = "CONTINUE"
  heartbeat_timeout      = var.lifecyclehook_instance_terminate_wait_time
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}


################################################################################
# Create autoscaling sns notifications
################################################################################
resource "aws_autoscaling_notification" "cc_asg_notifications" {
  count = var.sns_enabled == true ? 1 : 0
  group_names = [
    aws_autoscaling_group.cc_asg[*].name,
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = data.aws_sns_topic.cc_asg_topic_selected[0].arn
}

################################################################################
# Create a new sns topic and subscriptions per list of email address endpoints
################################################################################
resource "aws_sns_topic" "cc_asg_topic" {
  count = var.sns_enabled == true && var.byo_sns_topic == false ? 1 : 0
  name  = "${var.name_prefix}-cc-topic-${var.resource_tag}"
}

data "aws_sns_topic" "cc_asg_topic_selected" {
  count = var.sns_enabled == true ? 1 : 0
  name  = var.byo_sns_topic == false ? aws_sns_topic.cc_asg_topic[0].name : var.byo_sns_topic_name
}

resource "aws_sns_topic_subscription" "cc_asg_topic_email_subscription" {
  count     = var.byo_sns_topic == false && var.sns_enabled == true ? length(var.sns_email_list) : 0
  topic_arn = data.aws_sns_topic.cc_asg_topic_selected[0].arn
  protocol  = "email"
  endpoint  = var.sns_email_list[count.index]
}
