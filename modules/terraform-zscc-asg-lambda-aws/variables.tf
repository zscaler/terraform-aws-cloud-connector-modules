variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "cc_vm_prov_url" {
  type        = string
  description = "Zscaler Cloud Connector Provisioning URL"
}

variable "secret_name" {
  type        = string
  description = "AWS Secrets Manager Secret Name for Cloud Connector provisioning"
}

variable "autoscaling_group_names" {
  type        = list(string)
  description = "List of Autoscaling Group Names in a given Cloud Connector cluster/VPC for Lambda to monitor"
}

variable "asg_lambda_filename" {
  type        = string
  description = "Name of the lambda zip file without zip suffix"
  default     = "zscaler_cc_lambda_service"
}
