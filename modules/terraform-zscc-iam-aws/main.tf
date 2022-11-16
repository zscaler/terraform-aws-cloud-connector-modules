################################################################################
# Create IAM role and instance profile w/ SSM and Secrets Manager access policies
################################################################################

################################################################################
# Define AssumeRole access for EC2
################################################################################
data "aws_iam_policy_document" "instance_assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


################################################################################
# Define AssumeRole access for CC callhome trust feature
################################################################################
data "aws_iam_policy_document" "cc_callhome_policy_document" {
  version = "2012-10-17"
  statement {
    sid       = "AllowDelegationForCallhome"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::223544365242:role/callhome-delegation-role"]
  }
}


################################################################################
# Create IAM Policy for CC callhome
################################################################################
resource "aws_iam_policy" "cc_callhome_policy" {
  count       = var.byo_iam == false && var.cc_callhome_enabled ? var.iam_count : 0
  description = "Policy which allows STS AssumeRole when attached to a user or role. Used for CC callhome"
  name        = "${var.name_prefix}-cc-${count.index + 1}-callhome-policy-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc_callhome_policy_document.json
}

# Attach CC callhome policy to CC IAM Role
resource "aws_iam_role_policy_attachment" "cc_callhome_policy_attachment" {
  count      = var.byo_iam == false && var.cc_callhome_enabled ? var.iam_count : 0
  policy_arn = aws_iam_policy.cc_callhome_policy[count.index].arn
  role       = aws_iam_role.cc_node_iam_role[count.index].name
}


################################################################################
# Define AWS Managed Secrets Manager Policy
################################################################################
resource "aws_iam_role_policy_attachment" "secrets_manager_read_write" {
  count      = var.byo_iam == false ? var.iam_count : 0
  policy_arn = "arn:aws:iam::aws:policy/${var.iam_role_policy_smrw}"
  role       = aws_iam_role.cc_node_iam_role[count.index].name
}


################################################################################
# Define AWS Managed SSM Session Manager Policy
################################################################################
data "aws_iam_policy_document" "cc_session_manager_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "CCPermitSSMSessionManager"
    effect = "Allow"
    actions = ["ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cc_session_manager_policy" {
  count       = var.byo_iam == false ? var.iam_count : 0
  description = "Policy which permits CCs to register to SSM Manager for Console Connect functionality"
  name        = "${var.name_prefix}-cc-${count.index + 1}-ssm-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc_session_manager_policy_document.json
}

resource "aws_iam_role_policy_attachment" "cc_session_manager_attachment" {
  count      = var.byo_iam == false ? var.iam_count : 0
  policy_arn = aws_iam_policy.cc_session_manager_policy[count.index].arn
  role       = aws_iam_role.cc_node_iam_role[count.index].name
}


################################################################################
# Define AWS Managed Autoscale LifeCycle Policy
################################################################################
data "aws_iam_policy_document" "cc_autoscale_lifecycle_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "CCAllowAutoscaleLifecycleActions"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeLifecycleHookTypes",
      "autoscaling:DescribeLifecycleHooks",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cc_autoscale_lifecycle_policy" {
  count       = var.byo_iam == false && var.asg_enabled == true ? var.iam_count : 0
  description = "Policy which permits CCs to send lifecycle actions when hook is enabled"
  name        = "${var.name_prefix}-cc-${count.index + 1}-aslc-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc_autoscale_lifecycle_policy_document.json
}

resource "aws_iam_role_policy_attachment" "cc_autoscale_lifecycle_attachment" {
  count      = var.byo_iam == false && var.asg_enabled == true ? var.iam_count : 0
  policy_arn = aws_iam_policy.cc_autoscale_lifecycle_policy[count.index].arn
  role       = aws_iam_role.cc_node_iam_role[count.index].name
}


################################################################################
# Create CC IAM Role and Host/Instance Profile
################################################################################
resource "aws_iam_role" "cc_node_iam_role" {
  count              = var.byo_iam == false ? var.iam_count : 0
  name               = var.iam_count > 1 ? "${var.name_prefix}-cc-${count.index + 1}-node-iam-role-${var.resource_tag}" : "${var.name_prefix}-cc_node_iam_role-${var.resource_tag}"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  tags = merge(var.global_tags)
}

# Assign CC IAM Role to Instance Profile for CC instance attachment
resource "aws_iam_instance_profile" "cc_host_profile" {
  count = var.byo_iam == false ? var.iam_count : 0
  name  = var.iam_count > 1 ? "${var.name_prefix}-cc-${count.index + 1}-host-profile-${var.resource_tag}" : "${var.name_prefix}-cc-host-profile-${var.resource_tag}"
  role  = aws_iam_role.cc_node_iam_role[count.index].name

  tags = merge(var.global_tags)
}

# Or use existing IAM Instance Profile if specified in byo_iam
data "aws_iam_instance_profile" "cc_host_profile_selected" {
  count = var.byo_iam == false ? length(aws_iam_instance_profile.cc_host_profile[*].id) : length(var.byo_iam_instance_profile_id)
  name  = var.byo_iam == false ? element(aws_iam_instance_profile.cc_host_profile[*].name, count.index) : element(var.byo_iam_instance_profile_id, count.index)
}
