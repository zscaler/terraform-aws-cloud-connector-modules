output "gwlb_arn" {
  description = "GWLB ARN"
  value       = aws_lb.gwlb.arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.gwlb_target_group.arn
}
