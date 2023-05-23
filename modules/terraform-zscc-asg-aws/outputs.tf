output "availability_zone" {
  description = "Availability zones used for ASG"
  value       = aws_autoscaling_group.cc_asg.availability_zones
}
