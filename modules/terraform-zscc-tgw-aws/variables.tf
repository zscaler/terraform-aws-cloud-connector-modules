variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the TGW module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the TGW module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "tgw_name" {
  type        = string
  description = "Name tag for the Transit Gateway resource."
  default     = "zscc-tgw"
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones. Controls how many TGW attach and GWLB endpoint route entries are created in the hub."
  default     = 2
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "Input az_count must be set to a single value between 1 and 3."
  }
}

# Hub VPC inputs (outputs from terraform-zscc-network-aws module)
variable "hub_vpc_id" {
  type        = string
  description = "VPC ID of the Hub VPC (where Cloud Connectors and GWLB reside)."
}

variable "hub_tgw_attach_subnet_ids" {
  type        = list(string)
  description = "List of TGW attach subnet IDs in the Hub VPC (one per AZ). Sourced from the network module output tgw_attach_subnet_ids."
  validation {
    condition     = length(var.hub_tgw_attach_subnet_ids) >= 1
    error_message = "Input hub_tgw_attach_subnet_ids must contain at least one subnet ID."
  }
}

variable "hub_tgw_attach_route_table_ids" {
  type        = list(string)
  description = "List of route table IDs associated with the TGW attach subnets in the Hub VPC. Sourced from the network module output tgw_attach_route_table_ids."
  validation {
    condition     = length(var.hub_tgw_attach_route_table_ids) >= 1
    error_message = "Input hub_tgw_attach_route_table_ids must contain at least one route table ID."
  }
}

variable "hub_gwlb_endpoint_route_table_ids" {
  type        = list(string)
  description = "List of route table IDs associated with the GWLB endpoint subnets in the Hub VPC. Sourced from the network module output gwlb_endpoint_route_table_ids."
  validation {
    condition     = length(var.hub_gwlb_endpoint_route_table_ids) >= 1
    error_message = "Input hub_gwlb_endpoint_route_table_ids must contain at least one route table ID."
  }
}

variable "hub_cc_route_table_ids" {
  type        = list(string)
  description = "List of route table IDs associated with the CC subnets in the Hub VPC. Sourced from the network module output cc_subnet_route_table_ids. Used to add spoke CIDR → TGW routes so that East-West return traffic from CC (after GWLB inspection) is routed back to spoke VPCs via TGW rather than exiting via NAT GW."
  validation {
    condition     = length(var.hub_cc_route_table_ids) >= 1
    error_message = "Input hub_cc_route_table_ids must contain at least one route table ID."
  }
}

variable "gwlb_endpoint_ids" {
  type        = list(string)
  description = "List of GWLB Endpoint IDs (one per AZ) used to steer TGW-ingress traffic from the hub TGW attach subnets to Cloud Connector for inspection."
  validation {
    condition     = length(var.gwlb_endpoint_ids) >= 1
    error_message = "Input gwlb_endpoint_ids must contain at least one GWLB Endpoint ID."
  }
}

# Spoke 1 inputs
variable "spoke_1_vpc_cidr" {
  type        = string
  description = "CIDR block of Spoke 1 VPC. Used for static TGW routes and hub return routes."
}

variable "spoke_1_workload_subnet_ids" {
  type        = list(string)
  description = "List of workload subnet IDs in Spoke 1 VPC for the TGW VPC attachment."
}

variable "spoke_1_vpc_id" {
  type        = string
  description = "VPC ID of Spoke 1."
}

# Spoke 2 inputs
variable "spoke_2_vpc_cidr" {
  type        = string
  description = "CIDR block of Spoke 2 VPC. Used for static TGW routes and hub return routes."
}

variable "spoke_2_workload_subnet_ids" {
  type        = list(string)
  description = "List of workload subnet IDs in Spoke 2 VPC for the TGW VPC attachment."
}

variable "spoke_2_vpc_id" {
  type        = string
  description = "VPC ID of Spoke 2."
}
