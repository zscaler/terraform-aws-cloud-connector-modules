variable "name_prefix" {
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = "zscaler-cc"
}

variable "resource_tag" {
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "Cloud Connector VPC"
}

variable "cc_vm1_id" {
  description = "Cloud Connector 1 instance id"
}

variable "cc_vm2_id" {
  description = "Cloud Connector 2 instance id"
}

variable "cc_vm1_snid" {
  description = "Cloud Connector 1's service subnet id"
}

variable "cc_vm2_snid" {
  description = "Cloud Connector 2's service subnet id"
}

variable "cc_vm1_rte_list" {
  type = list(string)
  description = "List of route tables using Cloud Connector 1 instance id"
}

variable "cc_vm2_rte_list" {
  type = list(string)
  description = "List of route tables using Cloud Connector 2 instance id"
}

variable "http_probe_port" {
  description = "HTTP port to send the health probes on Cloud Connector cloud"
  default = 0
  validation {
          condition     = (
            var.http_probe_port == 0 ||
            var.http_probe_port == 80 ||
          ( var.http_probe_port >= 1024 && var.http_probe_port <= 65535 )
        )
          error_message = "Input http_probe_port must be set to a single value of 80 or any number between 1024-65535."
      }
}

variable "route_updater_filename" {
  description = "Route updater lambda deployment package filename"
  default     = "rte_updater_lambda.py.zip"
}

variable "route_updater_handler" {
  description = "Route updater lambda handler"
  default     = "rte_updater_lambda.lambda_handler"
}

variable "route_updater_runtime" {
  description = "Route updater lambda runtime"
  default     = "python3.8"
}

variable "global_tags" {
  description = "populate custom user provided tags"
}
