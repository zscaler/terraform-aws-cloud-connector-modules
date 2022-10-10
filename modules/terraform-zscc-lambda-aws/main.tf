################################################################################
# Create Lambda Environment
################################################################################


################################################################################
# Create IAM Role and Policy for Lambda
################################################################################
resource "aws_iam_role" "iam_for_cc_lambda" {
  name = "${var.vpc_id}_cc_lambda_iam"

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

# Create IAM Policy for Lambda
resource "aws_iam_policy" "iam_policy_for_cc_lambda" {
  name        = "${var.vpc_id}_cc_lambda_iam_policy"
  description = "IAM policy created for Checker lambda in ${var.vpc_id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AssignPrivateIpAddresses",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeRouteTables",
        "ec2:ReplaceRoute",
        "ec2:UnassignPrivateIpAddresses",
        "lambda:InvokeFunction",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "cc_lambda_execution_role_attachment" {
  policy_arn = aws_iam_policy.iam_policy_for_cc_lambda.arn
  role       = aws_iam_role.iam_for_cc_lambda.name
}

locals {
  rte1     = join(",", var.cc_vm1_rte_list)
  rte2     = join(",", var.cc_vm2_rte_list)
  environs = <<ENVIRONS
{
	"INSTANCES": "${var.cc_vm1_id},${var.cc_vm2_id}",
	"${var.cc_vm1_id}": {
		"RouteTables": "${local.rte1}",
		"HttpProbePort": "${var.http_probe_port}"
	},
	"${var.cc_vm2_id}": {
		"RouteTables": "${local.rte2}",
		"HttpProbePort": "${var.http_probe_port}"
	}
}
ENVIRONS
}

data "aws_subnet" "cc_subnets" {
  count = length(var.cc_subnet_ids)
  id    = element(var.cc_subnet_ids, count.index)
}


################################################################################
# Create AWS Security Group and rules for Lambda
################################################################################
resource "aws_security_group" "lambda_sg" {
  name        = "${var.name_prefix}-port-probe-lambda-sg-${var.resource_tag}"
  description = "Allow HTTP GET access to the specified port on CC"
  vpc_id      = var.vpc_id

  egress {
    from_port   = var.http_probe_port
    to_port     = var.http_probe_port
    protocol    = "tcp"
    cidr_blocks = data.aws_subnet.cc_subnets.*.cidr_block
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-lambda-sg-${var.resource_tag}" }
  )

  depends_on = [aws_iam_role_policy_attachment.cc_lambda_execution_role_attachment]
}


################################################################################
# Create Lambda Function
################################################################################
resource "aws_lambda_function" "cc_route_updater_lambda" {
  filename         = "${path.module}/${var.route_updater_filename}"
  function_name    = "${var.vpc_id}_cc_route_updater_fn"
  role             = aws_iam_role.iam_for_cc_lambda.arn
  handler          = var.route_updater_handler
  source_code_hash = filebase64sha256("${path.module}/${var.route_updater_filename}")
  runtime          = var.route_updater_runtime

  environment {
    variables = {
      ENVIRONS              = local.environs
      ROUTE_CHANGE_STRATEGY = "distribute_routes_equally"
    }
  }

  vpc_config {
    # Every CC subnet that must be reachable
    subnet_ids         = [data.aws_subnet.cc_subnets[0].id, try(data.aws_subnet.cc_subnets[1].id, data.aws_subnet.cc_subnets[0].id)] ## try is a catch-all in case only a single CC subnet ID is inputted to failback to the first
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  timeout = 60
}


################################################################################
# Create Cloudwatch rules, event targets, and triggers for failover execution
################################################################################
resource "aws_cloudwatch_event_rule" "cc_checker_timer" {
  name                = "${var.vpc_id}_cc_lambda_timer"
  description         = "Fire every 1 min"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "check_state_every1min" {
  target_id = aws_cloudwatch_event_rule.cc_checker_timer.name
  arn       = aws_lambda_function.cc_route_updater_lambda.arn
  rule      = aws_cloudwatch_event_rule.cc_checker_timer.name
}

resource "aws_lambda_permission" "allow_timer_to_call_cc_checker_lambda" {
  statement_id  = "AllowExecutionFromCloudWatchTimer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cc_route_updater_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cc_checker_timer.arn
}

resource "aws_cloudwatch_event_rule" "cc_state_change" {
  name          = "${var.vpc_id}_cc_state_change"
  description   = "Subscribes to CC VM state changes"
  event_pattern = <<EOF
{
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "source": [
    "aws.ec2"
  ],
  "detail": {
    "state": [
      "shutting-down",
      "terminated",
      "stopping",
      "stopped"
    ],
    "instance-id": [
      "${var.cc_vm1_id}",
      "${var.cc_vm2_id}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "check_instances_async" {
  target_id = aws_cloudwatch_event_rule.cc_state_change.name
  arn       = aws_lambda_function.cc_route_updater_lambda.arn
  rule      = aws_cloudwatch_event_rule.cc_state_change.name
}

resource "aws_lambda_permission" "allow_state_checker_to_call_cc_checker_lambda" {
  statement_id  = "AllowExecutionFromCloudWatchEventChecker"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cc_route_updater_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cc_state_change.arn
}

resource "aws_cloudwatch_log_group" "checker_log_group" {
  name = "/aws/lambda/${var.vpc_id}_cc_route_updater_fn"
}
