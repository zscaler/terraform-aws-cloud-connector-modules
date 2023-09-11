variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Cloud Connector IAM module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Cloud Connector IAM module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "iam_count" {
  type        = number
  description = "Default number IAM roles/policies/profiles to create"
  default     = 1
}

variable "byo_iam" {
  type        = bool
  description = "Bring your own IAM Instance Profile for Cloud Connector. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo_iam_instance_profile_id"
  default     = false
}

variable "byo_iam_instance_profile_id" {
  type        = list(string)
  description = "Existing IAM Instance Profile IDs for Cloud Connector association"
  default     = null
}

variable "asg_enabled" {
  type        = bool
  description = "Determines whether or not to create the cc_autoscale_lifecycle_policy IAM Policy and attach it to the CC IAM Role"
  default     = false
}

variable "secret_name" {
  type        = string
  description = "AWS Secrets Manager Secret Name for Cloud Connector provisioning"
}
