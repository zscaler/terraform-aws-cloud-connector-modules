# AWS ZTGW Consumer-Brownfield Example

This example is designed for **Application, Cloud, and DevOps teams** who need to connect an **EXISTING customer AWS VPC** to an already-provisioned ZTGW Endpoint Service.

## Key Highlights:
* **Zero Zscaler API Keys:** You do not need Zscaler admin credentials or OneAPI access.
* **Non-Disruptive:** Connects to an existing VPC, creates the local Gateway Load Balancer VPC Endpoint interface, and steers designated route tables.
* **Route Conflict Safety:** Automatically resolves existing default routes (`0.0.0.0/0` e.g. to IGW) if `overwrite_existing_routes = true`.

## Usage
```bash
cp terraform.tfvars.example terraform.tfvars
# Fill in your VPC ID, Endpoint Subnet ID, Route Table ID, and the endpoint_service_name
terraform init
terraform apply
```
