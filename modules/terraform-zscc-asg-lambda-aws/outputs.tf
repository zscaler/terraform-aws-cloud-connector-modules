output "lambda_arn" {
  description = "Lambda Function ARN"
  value       = aws_lambda_function.asg_lambda_function.arn
}
