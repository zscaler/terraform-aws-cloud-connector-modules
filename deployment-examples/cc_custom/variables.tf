# aws variables

variable "aws_region" {
  description = "The AWS region."
  default     = "us-west-2"
}

variable "name_prefix" {
  description = "The name prefix for all your resources"
  default     = "zsdemo"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "10.1.0.0/16"
}

variable "cc_count" {
  description = "Default number of Cloud Connector appliances to create"
  default     = 2
}

variable "az_count" {
  description = "Default number of subnets to create based on availability zone"
  type = number
  default     = 2
  validation {
          condition     = (
          (var.az_count >= 1 && var.az_count <= 3)
        )
          error_message = "Input az_count must be set to a single value between 1 and 3. Note* some regions have greater than 3 AZs. Please modify az_count validation in variables.tf if you are utilizing more than 3 AZs in a region that supports it. https://aws.amazon.com/about-aws/global-infrastructure/regions_az/."
      }
}

variable "http_probe_port" {
  description = "port for Cloud Connector cloud init to enable listener port for HTTP probe from LB"
  default = 0
  validation {
          condition     = (
            var.http_probe_port == 0  ||
            var.http_probe_port == 80 ||
          ( var.http_probe_port >= 1024 && var.http_probe_port <= 65535 )
        )
          error_message = "Input http_probe_port must be set to a single value of 80 or any number between 1024-65535."
      }
}

variable "cc_vm_prov_url" {
  description = "Zscaler Cloud Connector Provisioning URL"
  type        = string
}

variable "secret_name" {
  description = "AWS Secrets Manager Secret Name for Cloud Connector provisioning"
  type        = string
}

variable "ccvm_instance_type" {
  description = "Cloud Connector Instance Type"
  default     = "m5.large"
  validation {
          condition     = ( 
            var.ccvm_instance_type == "t3.medium"  ||
            var.ccvm_instance_type == "m5.large"   ||
            var.ccvm_instance_type == "c5.large"   ||
            var.ccvm_instance_type == "c5a.large"  ||
            var.ccvm_instance_type == "m5.2xlarge" ||
            var.ccvm_instance_type == "c5.2xlarge" ||
            var.ccvm_instance_type == "m5.4xlarge" ||
            var.ccvm_instance_type == "c5.4xlarge"
          )
          error_message = "Input ccvm_instance_type must be set to an approved vm instance type."
      }
}

variable "owner_tag" {
  description = "populate custom owner tag attribute"
  type = string
  default = "zscc-admin"
}

variable "tls_key_algorithm" {
  default   = "RSA"
  type      = string
}

variable "cc_instance_size" {
  default = "small"
   validation {
          condition     = ( 
            var.cc_instance_size == "small"  ||
            var.cc_instance_size == "medium" ||
            var.cc_instance_size == "large"
          )
          error_message = "Input cc_instance_size must be set to an approved cc instance type."
      }
}

variable "byo_vpc" {
  default     = false
  type        = bool
  description = "Bring your own AWS VPC for Cloud Connector"
}

variable "byo_vpc_id" {
  default     = null
  type        = string
  description = "User provided existing AWS VPC ID"
}

variable "byo_subnets" {
  default     = false
  type        = bool
  description = "Bring your own AWS Subnets for Cloud Connector"
}

variable "byo_subnet_ids" {
  default     = null
  type        = list(string)
  description = "User provided existing AWS Subnet IDs"
}

variable "byo_igw" {
  default     = false
  type        = bool
  description = "Bring your own AWS VPC for Cloud Connector"
}

variable "byo_igw_id" {
  default     = null
  type        = string
  description = "User provided existing AWS Internet Gateway ID"
}

variable "byo_ngw" {
  default     = false
  type        = bool
  description = "Bring your own AWS NAT Gateway(s) Cloud Connector"
}

variable "byo_ngw_ids" {
  default     = null
  type        = list(string)
  description = "User provided existing AWS NAT Gateway IDs"
}

locals {
  small_cc_instance  = ["t3.medium","m5.large","c5.large","c5a.large","m5.2xlarge","c5.2xlarge","m5.4xlarge","c5.4xlarge"]
  medium_cc_instance = ["m5.2xlarge","c5.2xlarge","m5.4xlarge","c5.4xlarge"]
  large_cc_instance  = ["m5.4xlarge","c5.4xlarge"]
  
  valid_cc_create = (
contains(local.small_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "small"   ||
contains(local.medium_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "medium" ||
contains(local.large_cc_instance, var.ccvm_instance_type) && var.cc_instance_size == "large"
 )
}

variable "cross_zone_lb_enabled" {
  default = false
  type = bool
  description = "Toggle cross-zone loadbalancing of GWLB on/off"
}

variable "domain_names" {
  type        = map(map(string))
  description = "Domain names fqdn/wildcard to have Route 53 redirect DNS requests to Cloud Connector for ZPA. Refer to terraform.tfvars step 10"
  default     = null
}

variable "target_address" {
  type        = list(string)
  description = "Route 53 DNS queries will be forwarded to these Zscaler Global VIP addresses"
  default     = ["185.46.212.88" , "185.46.212.89"]
}

variable "zpa_enabled" {
  default = false
  type = bool
  description = "Configure Route 53 Subnets, Route Tables, and Resolvers for ZPA DNS redirection"
}

variable "workload_route_table_ids_to_cc_1" {
  default     = null
  type        = list(string)
  description = "User provided existing AWS Route Table IDs sending to Cloud Connector 1 in pair"
}

variable "workload_route_table_ids_to_cc_2" {
  default     = null
  type        = list(string)
  description = "User provided existing AWS Route Table IDs sending to Cloud Connector 2 in pair"
}

variable "lambda_enabled" {
  default = false
  type = bool
  description = "Enable Lambda module for Cloud Connector monitoring and workload route failover"
}

variable "cc_callhome_enabled" {
  description = "determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role"
  default = "true"
  type  = bool
}