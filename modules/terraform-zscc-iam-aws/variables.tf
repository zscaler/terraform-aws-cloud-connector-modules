variable "name_prefix" {
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = "zscaler-cc"
}

variable "resource_tag" {
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = "cloud-connector"
}

variable "global_tags" {
  type        = map(any)
  description = "populate custom user provided tags"
}

variable "iam_role_policy_smrw" {
  description = "Cloud Connector EC2 Instance IAM Role"
  default     = "SecretsManagerReadWrite"
}

variable "iam_role_policy_ssmcore" {
  description = "Cloud Connector EC2 Instance IAM Role"
  default     = "AmazonSSMManagedInstanceCore"
}

variable "iam_count" {
  description = "Default number IAM roles/policies/profiles to create"
  default     = 1
}

variable "cc_callhome_enabled" {
  description = "determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role"
  default     = "true"
  type        = bool
}

variable "byo_iam" {
  default     = false
  type        = bool
  description = "Bring your own IAM Instance Profile for Cloud Connector"
}

variable "byo_iam_instance_profile_id" {
  type        = list(string)
  default     = null
  description = "IAM Instance Profile ID for Cloud Connector association"
}