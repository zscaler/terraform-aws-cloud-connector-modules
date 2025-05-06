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
# Define AWS Managed Secrets Manager Get Secrets Policy
################################################################################
# Retrieve Secret Manager ARN by friendly name
data "aws_secretsmanager_secret" "cc_secret_name" {
  name = var.secret_name
}

# Define policy to GetSecretValue from Secret Name
data "aws_iam_policy_document" "cc_get_secrets_policy_document" {
  version = "2012-10-17"
  statement {
    sid       = "CCPermitGetSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", ]
    resources = [data.aws_secretsmanager_secret.cc_secret_name.id]
  }
}

# Create Get Secrets Policy
resource "aws_iam_policy" "cc_get_secrets_policy" {
  count       = var.byo_iam == false ? var.iam_count : 0
  description = "Policy which permits CCs to retrieve and decrypt the encrypted data from Secrets Manager"
  name        = "${var.name_prefix}-cc-${count.index + 1}-get-secrets-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc_get_secrets_policy_document.json
}

# Attach Get Secrets Policy to IAM Role
resource "aws_iam_role_policy_attachment" "cc_get_secrets_attachment" {
  count      = var.byo_iam == false ? var.iam_count : 0
  policy_arn = aws_iam_policy.cc_get_secrets_policy[count.index].arn
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
    # https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-create-iam-instance-profile.html
  }
}

# Create SSM Policy
resource "aws_iam_policy" "cc_session_manager_policy" {
  count       = var.byo_iam == false ? var.iam_count : 0
  description = "Policy which permits CCs to register to SSM Manager for Console Connect functionality"
  name        = "${var.name_prefix}-cc-${count.index + 1}-ssm-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc_session_manager_policy_document.json
}

# Attach SSM Policy to IAM Role
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
    sid    = "ASGAllowDescribe"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstanceStatus",
      "autoscaling:DescribeLifecycleHookTypes",
      "autoscaling:DescribeLifecycleHooks",
      "autoscaling:DescribeAutoScalingInstances"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ASGAllowAutoscaleLifecycleActions"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat"
    ]
    #Restrict autoscaling actions to only your own ASG(s) if var.asg_arns provided. Else, default to any
    resources = coalescelist(var.asg_arns, ["*"])
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
# Define AWS Managed CloudWatch Metrics Policy
################################################################################
data "aws_iam_policy_document" "cc_metrics_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "CCAllowCloudWatchMetricsRW"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
    #Restrict cloudwatch metrics posting only to fixed Zscaler/CloudConnectors namespace
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["Zscaler/CloudConnectors"]
    }
  }

  statement {
    sid    = "CCAllowCloudWatchMetricsRO"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "CCAllowEC2DescribeTags"
    effect = "Allow"
    actions = [
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cc_metrics_policy" {
  count       = var.byo_iam == false ? var.iam_count : 0
  description = "Policy which permits CCs to send custom metrics to CloudWatch"
  name        = "${var.name_prefix}-cc-${count.index + 1}-metrics-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc_metrics_policy_document.json
}

resource "aws_iam_role_policy_attachment" "cc_metrics_attachment" {
  count      = var.byo_iam == false ? var.iam_count : 0
  policy_arn = aws_iam_policy.cc_metrics_policy[count.index].arn
  role       = aws_iam_role.cc_node_iam_role[count.index].name
}


################################################################################
# Define AWS SQS/SNS Policy for Cloud Connector Tags subscription
################################################################################
data "aws_iam_policy_document" "cc_tags_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "CCAllowTags"
    effect = "Allow"
    actions = [
      "sns:ListTopics",
      "sns:ListSubscriptions",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sqs:CreateQueue",
      "sqs:DeleteQueue"
    ]
    resources = ["*"]

    #Restrict policy to conditions configured via var.iam_tags_conditions
    dynamic "condition" {
      for_each = var.iam_tags_condition
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_policy" "cc_tags_policy" {
  count       = var.byo_iam == false && var.cloud_tags_enabled == true ? var.iam_count : 0
  description = "Policy which permits CCs to subscribe for tags changes"
  name        = "${var.name_prefix}-cc-${count.index + 1}-tags-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc_tags_policy_document.json
}

resource "aws_iam_role_policy_attachment" "cc_tags_attachment" {
  count      = var.byo_iam == false && var.cloud_tags_enabled == true ? var.iam_count : 0
  policy_arn = aws_iam_policy.cc_tags_policy[count.index].arn
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
  count = var.byo_iam ? 0 : var.iam_count
  name  = var.iam_count > 1 ? "${var.name_prefix}-cc-${count.index + 1}-host-profile-${var.resource_tag}" : "${var.name_prefix}-cc-host-profile-${var.resource_tag}"
  role  = aws_iam_role.cc_node_iam_role[count.index].name

  tags = merge(var.global_tags)
}

# Or use existing IAM Instance Profile if specified in byo_iam
data "aws_iam_instance_profile" "cc_host_profile_selected" {
  count = var.byo_iam ? length(var.byo_iam_instance_profile_id) : 0
  name  = element(var.byo_iam_instance_profile_id, count.index)
}
