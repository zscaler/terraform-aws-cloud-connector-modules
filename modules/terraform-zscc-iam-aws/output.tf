output "iam_instance_profile_id" {
  value = aws_iam_instance_profile.cc-host-profile.*.id
}

output "iam_instance_profile_arn" {
  value = aws_iam_instance_profile.cc-host-profile.*.arn
}