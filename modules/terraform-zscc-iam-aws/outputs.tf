output "iam_instance_profile_id" {
  description = "IAM Instance Profile Name"
  value       = var.byo_iam ? data.aws_iam_instance_profile.cc_host_profile_selected[*].name : aws_iam_instance_profile.cc_host_profile[*].name
}

output "iam_instance_profile_arn" {
  description = "IAM Instance Profile ARN"
  value       = var.byo_iam ? data.aws_iam_instance_profile.cc_host_profile_selected[*].arn : aws_iam_instance_profile.cc_host_profile[*].arn
}
