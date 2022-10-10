output "iam_instance_profile_id" {
  description = "IAM Instance Profile Name"
  value       = data.aws_iam_instance_profile.cc_host_profile_selected.*.name
}

output "iam_instance_profile_arn" {
  description = "IAM Instance Profile ARN"
  value       = data.aws_iam_instance_profile.cc_host_profile_selected.*.arn
}
