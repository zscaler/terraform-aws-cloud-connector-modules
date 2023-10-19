################################################################################
# Create IAM Role and Policy for Lambda
################################################################################
resource "aws_iam_role" "asg_lambda_iam_role" {
  name = "${var.name_prefix}-asg-lambda-iam-role-${var.resource_tag}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


################################################################################
# Define AWS Managed Secrets Manager Get Secrets Policy
################################################################################
# Retrieve Secret Manager ARN by friendly name
data "aws_secretsmanager_secret" "lambda_secret_name" {
  name = var.secret_name
}

# Define policy to GetSecretValue from Secret Name
data "aws_iam_policy_document" "lambda_get_secrets_policy_document" {
  version = "2012-10-17"
  statement {
    sid       = "LambdaPermitGetSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", ]
    resources = [data.aws_secretsmanager_secret.lambda_secret_name.id]
  }
}

# Create Get Secrets Policy
resource "aws_iam_policy" "lambda_get_secrets_policy" {
  description = "Policy which permits Lambda to retrieve and decrypt the encrypted data from Secrets Manager"
  name        = "${var.name_prefix}-lambda-get-secrets-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.lambda_get_secrets_policy_document.json
}

# Attach Get Secrets Policy to IAM Role
resource "aws_iam_role_policy_attachment" "lambda_get_secrets_attachment" {
  policy_arn = aws_iam_policy.lambda_get_secrets_policy.arn
  role       = aws_iam_role.asg_lambda_iam_role.name
}


################################################################################
# Define AWS Managed Autoscale Lifecycle Policy
################################################################################
# Define policy for lambda to access and invoke lifecycle actions
data "aws_iam_policy_document" "lambda_autoscale_lifecycle_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "LambdaAllowAutoscaleLifecycleActions"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeLifecycleHookTypes",
      "autoscaling:DescribeLifecycleHooks",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:SetInstanceHealth",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeWarmPool",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

# Create lambda lifecycle policy
resource "aws_iam_policy" "lambda_autoscale_lifecycle_policy" {
  description = "Policy which permits lambda to send lifecycle actions"
  name        = "${var.name_prefix}-asg-lambda-aslc-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.lambda_autoscale_lifecycle_policy_document.json
}

# Attach Lambda lifeycle policy to IAM Role
resource "aws_iam_role_policy_attachment" "lambda_autoscale_lifecycle_attachment" {
  policy_arn = aws_iam_policy.lambda_autoscale_lifecycle_policy.arn
  role       = aws_iam_role.asg_lambda_iam_role.name
}


################################################################################
# Define AWS Managed CloudWatch Metrics Policy
################################################################################
# Define lambda policy for collecting Cloudwatch metrics
data "aws_iam_policy_document" "lambda_metrics_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "LambdaAllowCloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

# Create lambda metrics policy
resource "aws_iam_policy" "lambda_metrics_policy" {
  description = "Policy which permits lambda to retrieve custom metrics from CloudWatch"
  name        = "${var.name_prefix}-asg-lambda-get-metrics-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.lambda_metrics_policy_document.json
}

# Attach lambda metrics policy to IAM Role
resource "aws_iam_role_policy_attachment" "lambda_metrics_attachment" {
  policy_arn = aws_iam_policy.lambda_metrics_policy.arn
  role       = aws_iam_role.asg_lambda_iam_role.name
}


################################################################################
# Define AWS Managed Logs Policy
################################################################################
# Define lambda policy for streaming logs
data "aws_iam_policy_document" "lambda_logs_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "LambdaAllowLogStreamEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.asg_cloudwatch_log_group.arn}:*"]
  }
}

# Create lambda logs policy
resource "aws_iam_policy" "lambda_logs_policy" {
  description = "Policy which permits lambda to create and send logs"
  name        = "${var.name_prefix}-asg-lambda-send-logs-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.lambda_logs_policy_document.json
}

# Attach lambda logs policy to IAM Role
resource "aws_iam_role_policy_attachment" "lambda_logs_attachment" {
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
  role       = aws_iam_role.asg_lambda_iam_role.name
}


################################################################################
# Create Lambda Function
################################################################################
resource "aws_lambda_function" "asg_lambda_function" {
  function_name    = "${var.name_prefix}_asg_lambda_function_${var.resource_tag}"
  handler          = "${var.asg_lambda_filename}.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/${var.asg_lambda_filename}.zip"
  source_code_hash = filebase64sha256("${path.module}/${var.asg_lambda_filename}.zip")
  role             = aws_iam_role.asg_lambda_iam_role.arn
  timeout          = 180
  memory_size      = 256

  environment {
    variables = {
      ASG_NAMES              = jsonencode(var.autoscaling_group_names)
      CC_URL                 = var.cc_vm_prov_url
      SECRET_NAME            = var.secret_name
      HC_DATA_POINTS         = "10"
      HC_UNHEALTHY_THRESHOLD = "7"
    }
  }

  tags = merge(var.global_tags)
}


################################################################################
# Create Cloudwatch Event Rules and Targets for Scheduler
################################################################################
resource "aws_cloudwatch_event_rule" "asg_cloudwatch_scheduler_event_rule" {
  name                = "${var.name_prefix}-cc-asg-scheduled-event-rule-${var.resource_tag}"
  description         = "EventBridge rule to trigger Lambda function every 1 minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "asg_cloudwatch_scheduler_event_target" {
  rule      = aws_cloudwatch_event_rule.asg_cloudwatch_scheduler_event_rule.name
  target_id = aws_lambda_function.asg_lambda_function.function_name
  arn       = aws_lambda_function.asg_lambda_function.arn
}

resource "aws_lambda_permission" "asg_cloudwatch_scheduler_event_permission" {
  statement_id  = "lambda-permission-${aws_cloudwatch_event_rule.asg_cloudwatch_scheduler_event_rule.id}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asg_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_cloudwatch_scheduler_event_rule.arn
}


################################################################################
# Create Cloudwatch Event Rules and Targets for Lifecycle changes
################################################################################
resource "aws_cloudwatch_event_rule" "asg_cloudwatch_lifecycle_event_rule" {
  name        = "${var.name_prefix}-cc-asg-lifecycle-event-rule-${var.resource_tag}"
  description = "Event rule for EC2 Instance-terminate Lifecycle Action"

  event_pattern = <<PATTERN
{
  "source": ["aws.autoscaling"],
  "detail-type": ["EC2 Instance-terminate Lifecycle Action"],
  "detail": {
    "AutoScalingGroupName": ${jsonencode(var.autoscaling_group_names)}
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "asg_cloudwatch_lifecycle_event_target" {
  rule      = aws_cloudwatch_event_rule.asg_cloudwatch_lifecycle_event_rule.name
  target_id = aws_lambda_function.asg_lambda_function.function_name
  arn       = aws_lambda_function.asg_lambda_function.arn
}

resource "aws_lambda_permission" "asg_cloudwatch_lifecycle_permission" {
  statement_id  = "lambda-permission-${aws_cloudwatch_event_rule.asg_cloudwatch_lifecycle_event_rule.id}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asg_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_cloudwatch_lifecycle_event_rule.arn
}


################################################################################
# Create Cloudwatch Event Rules and Targets for EC2 Terminations
################################################################################
resource "aws_cloudwatch_event_rule" "asg_cloudwatch_instance_termination_event_rule" {
  name        = "${var.name_prefix}-cc-asg-instance-termination-event-rule-${var.resource_tag}"
  description = "Event rule for EC2 Instance-termination without Lifecycle Action"

  event_pattern = <<PATTERN
{
  "source": ["aws.ec2"],
  "detail-type": ["EC2 Instance State-change Notification"],
  "detail": {
    "state": ["terminated"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "asg_cloudwatch_instance_termination_event_target" {
  rule      = aws_cloudwatch_event_rule.asg_cloudwatch_instance_termination_event_rule.name
  target_id = aws_lambda_function.asg_lambda_function.function_name
  arn       = aws_lambda_function.asg_lambda_function.arn
}

resource "aws_lambda_permission" "asg_cloudwatch_instance_termination_permission" {
  statement_id  = "lambda-permission-${aws_cloudwatch_event_rule.asg_cloudwatch_instance_termination_event_rule.id}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asg_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_cloudwatch_instance_termination_event_rule.arn
}


################################################################################
# Create Cloudwatch log Group
################################################################################
resource "aws_cloudwatch_log_group" "asg_cloudwatch_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.asg_lambda_function.id}"
  retention_in_days = var.log_group_retention_days
}
