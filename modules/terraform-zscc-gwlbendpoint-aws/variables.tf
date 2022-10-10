variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the GWLB Endpoint module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the GWLB Endpoint module resources"
  default     = null
}

variable "vpc_id" {
  type        = string
  description = "Cloud Connector VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of Subnet ID to create GLWB Endpoints in"
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "gwlb_arn" {
  type        = string
  description = "ARN of GWLB for Endpoint Service to be assigned"
}

variable "acceptance_required" {
  type        = bool
  description = "Whether to require manual acceptance of any VPC Endpoint registration attempts to the Endpoint Service or not. Default is false"
  default     = false
}

variable "allowed_principals" {
  type        = list(string)
  description = "List of AWS Principal ARNs who are allowed access to the GWLB Endpoint Service. E.g. [\"arn:aws:iam::1234567890:root\"]`. See https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#accept-reject-connection-requests"
  default     = []
}
