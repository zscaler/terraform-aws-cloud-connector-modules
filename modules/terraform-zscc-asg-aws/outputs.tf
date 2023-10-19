output "availability_zone" {
  description = "Availability zones used for ASG"
  value       = flatten(aws_autoscaling_group.cc_asg[*].availability_zones)
}

output "autoscaling_group_ids" {
  description = "Autoscaling group ID"
  value       = aws_autoscaling_group.cc_asg[*].id
}

output "launch_template_id" {
  description = "Autoscaling Launch Template ID"
  value       = aws_launch_template.cc_launch_template[0].id
}
