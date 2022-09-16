output "gwlb_arn" {
  value = aws_lb.gwlb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.gwlb-target-group.arn
}