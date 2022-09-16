################################################################################
# Pull region information
################################################################################
data "aws_region" "current" {}

resource "null_resource" "error-checker" {
  count = local.valid_cc_create ? 0 : 1 # 0 means no error is thrown, else throw error
  provisioner "local-exec" {
    command = <<EOF
      echo "Cloud Connector parameters were invalid. No appliances were created. Please check the documentation and cc_instance_size / ccvm_instance_type values that were chosen" >> ${path.root}/errorlog.txt
EOF
  }
}


################################################################################
# Locate Latest CC AMI by product code
################################################################################
data "aws_ami" "cloudconnector" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["2l8tfysndbav4tv2nfjwak3cu"]
  }

  owners = ["aws-marketplace"]
}


################################################################################
# Create launch template for Cloud Connector autoscaling group instance creation. 
# Mgmt and service interface device indexes are swapped to support ASG + GWLB 
# instance association
################################################################################
resource "aws_launch_template" "cc-launch-template" {
  count         = local.valid_cc_create && var.cc_instance_size == "small" ? 1 : 0
  name          = "${var.name_prefix}-cc-launch-template-${var.resource_tag}"
  image_id      = data.aws_ami.cloudconnector.id
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

  lifecycle {
    create_before_destroy = true
  }
}


################################################################################
# Create Cloud Connector autoscaling group
################################################################################
resource "aws_autoscaling_group" "cc-asg" {
  name                      = "${var.name_prefix}-cc-asg-${var.resource_tag}"
  vpc_zone_identifier       = distinct(var.cc_subnet_ids)
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period

  launch_template {
    id      = aws_launch_template.cc-launch-template.*.id[0]
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

  lifecycle {
    ignore_changes = [load_balancers, desired_capacity, target_group_arns]
  }
}


################################################################################
# Automatically associate all Cloud Connector instances created by autoscaling 
# group to GWLB Target Group
################################################################################
resource "aws_autoscaling_attachment" "cc-asg-attachment-gwlb" {
  autoscaling_group_name = aws_autoscaling_group.cc-asg.id
  lb_target_group_arn    = var.target_group_arn
}


################################################################################
# Create autoscaling group policy based on dynamic Target Tracking Scaling on 
# average CPU
################################################################################
resource "aws_autoscaling_policy" "cc-asg-target-tracking-policy" {
  name                   = "${var.name_prefix}-cc-asg-target-policy-${var.resource_tag}"
  autoscaling_group_name = aws_autoscaling_group.cc-asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.target_tracking_metric
    }
    target_value = var.target_cpu_util_value
  }
}