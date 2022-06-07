/*
Create Lambda
Environment
Attach IAM policy
Setup parameter store
Triggers
Cloud watch end points
*/

resource "aws_iam_role" "iam_for_cc_lambda" {
  name = "${var.vpc}_cc_lambda_iam"

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

resource "aws_iam_policy" "iam_policy_for_cc_lambda" {
  name        = "${var.vpc}_cc_lambda_iam_policy"
  description = "IAM policy created for Checker lambda in ${var.vpc}"

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

resource "aws_iam_role_policy_attachment" "cc_lambda_execution_role_attachment" {
  policy_arn = aws_iam_policy.iam_policy_for_cc_lambda.arn
  role       = aws_iam_role.iam_for_cc_lambda.name
}

locals {
  rte1            = join(",", var.cc_vm1_rte_list)
  rte2            = join(",", var.cc_vm2_rte_list)
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
data "aws_security_group" selected {
  vpc_id = var.vpc
  name   = "default"
}

data "aws_instance" "cc-vm1" {
  instance_id = var.cc_vm1_id
}

data "aws_subnet" "cc-vm1" {
  id = var.cc_vm1_snid
}

data "aws_instance" "cc-vm2" {
  instance_id = var.cc_vm2_id
}

data "aws_subnet" "cc-vm2" {
  id = var.cc_vm2_snid
}

resource "aws_security_group" "lambda-sg" {
  name        = "${var.name_prefix}-port-probe-lambda-sg-${var.resource_tag}"
  description = "Allow HTTP GET access to the specified port on CC"
  vpc_id      = var.vpc

  egress {
    from_port   = var.http_probe_port
    to_port     = var.http_probe_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.cc-vm1.cidr_block, data.aws_subnet.cc-vm2.cidr_block]
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

# Checker Lambda
resource "aws_lambda_function" "cc_route_updater_lambda" {
  filename         = "${path.module}/${var.route_updater_filename}"
  function_name    = "${var.vpc}_cc_route_updater_fn"
  role             = aws_iam_role.iam_for_cc_lambda.arn
  handler          = var.route_updater_handler
  source_code_hash = filebase64sha256("${path.module}/${var.route_updater_filename}")
  runtime          = var.route_updater_runtime

  environment {
    variables = {
      ENVIRONS = local.environs
      ROUTE_CHANGE_STRATEGY = "distribute_routes_equally"
    }
  }

  vpc_config {
    # Every CC subnet that must be reachable
    subnet_ids         = [var.cc_vm1_snid, var.cc_vm2_snid]
    #security_group_ids = [data.aws_security_group.selected.id]
    security_group_ids = [aws_security_group.lambda-sg.id]
  }

  timeout = 60
}

resource "aws_cloudwatch_event_rule" "cc_checker_timer" {
  name                = "${var.vpc}_cc_lambda_timer"
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
  name          = "${var.vpc}_cc_state_change"
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
  name = "/aws/lambda/${var.vpc}_cc_route_updater_fn"
}


