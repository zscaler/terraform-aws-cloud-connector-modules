# AWS ZTGW Gateway-Only Example

This example is designed for **InfoSec and Central Platform teams** who need to provision a managed Zscaler Zero Trust Gateway in AWS via Zscaler OneAPI without managing individual customer application VPCs.

## What this module does:
1. Provisions the Zscaler Cloud Connector cluster and Gateway Load Balancer inside Zscaler's Dataplane account in the specified region.
2. Whitelists customer 12-digit AWS account IDs on the resulting VPC Endpoint Service.
3. Outputs the `endpoint_service_name` handle (e.g. `com.amazonaws.vpce.us-east-1.vpce-svc-0...`).

## Usage
```bash
cp terraform.tfvars.example terraform.tfvars
# Fill in credentials and account IDs
terraform init
terraform apply
```

Hand off the output `endpoint_service_name` to your application/cloud teams to connect their VPCs via `examples/aws/consumer-brownfield`.
