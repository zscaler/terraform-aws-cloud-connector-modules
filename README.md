<a href="https://terraform.io">
    <img src="https://raw.githubusercontent.com/hashicorp/terraform-website/master/public/img/logo-text.svg" alt="Terraform logo" title="Terraform" height="50" width="250" />
</a>
<a href="https://www.zscaler.com/">
    <img src="https://www.zscaler.com/themes/custom/zscaler/logo.svg" alt="Zscaler logo" title="Zscaler" height="50" width="250" />
</a>

Zscaler Cloud Connector AWS Terraform Modules
===========================================================================================================

# **README for AWS Terraform**
This README serves as a quick start guide to deploy Zscaler Cloud Connector resources in an AWS cloud using Terraform. To learn more about
the resources created when deploying Cloud Connector with Terraform, see [Deployment Templates for Zscaler Cloud Connector](https://help.zscaler.com/cloud-branch-connector/deployment-templates-zscaler-cloud-connector).

## **AWS Deployment Scripts for Terraform**

Use this repository to create the deployment resources required to deploy and operate Cloud Connector in a new or existing virtual private
cloud (VPC). The [examples](examples/) directory contains complete automation scripts for both greenfield/POV and brownfield/production use.

## **Prerequisites**

The AWS Terraform scripts leverage Terraform v1.1.9 which includes full binary and provider support for macOS M1 chips, but any Terraform
version 0.13.7 should be generally supported.

-   provider registry.terraform.io/hashicorp/aws v4.59.x
-   provider registry.terraform.io/hashicorp/random v3.3.x
-   provider registry.terraform.io/hashicorp/local v2.2.x
-   provider registry.terraform.io/hashicorp/null v3.1.x
-   provider registry.terraform.io/providers/hashicorp/tls v3.4.x

### **AWS requirements**

1.  A valid AWS account with Administrator Access to deploy required resources
2.  AWS ACCESS KEY ID
3.  AWS SECRET ACCESS KEY
4.  AWS Region (E.g. us-west-2)
5.  Subscribe and accept the terms of using Amazon Linux 2 (for base deployments with workloads + bastion) at [this link](https://aws.amazon.com/marketplace/pp/prodview-zc4x2k7vt6rpu)
6.  Subscribe and accept the terms of using Zscaler Cloud Connector image at [this link](https://aws.amazon.com/marketplace/pp/prodview-cvzx4oiv7oljm)

### **Zscaler requirements**

7.  A valid Zscaler Cloud Connector provisioning URL generated from the Zscaler Cloud & Branch Connector Admin Portal
8.  Zscaler Cloud Connector Credentials (api key, username, password) are stored in AWS Secrets Manager

### **Terraform client requirements**
9. If executing Terraform via the "zsec" wrapper bash script, it is advised that you run from a MacOS or Linux workstation. Minimum installed application requirements to successfully from the script are:
- AWS CLI (to generate temporary session token if required)
- bash
- curl
- unzip
<br>
<br>

## **Greenfield Deployments** 

Use this if you are building an entire cluster from the ground up. These templates include a bastion host and test workloads and are designed for greenfield/POV testing. 

###  **Starter Deployment Template**

Use the [**Starter Deployment Template**](examples/base_1cc/) to deploy your Cloud Connector in a new VPC.

### **Starter Deployment Template with ZPA**

Use the [**Starter Deployment Template with ZPA**](examples/base_1cc_zpa) to deploy your Cloud Connector in a new VPC with ZPA DNS resolver capability.

### **Starter Deployment Template with High Availability (deprecated)**

Use the [**Starter Deployment Template with High Availability**](examples/base_2cc) to deploy your Cloud Connector in a new VPC with lambda health monitoring for failover. This template achieves high availability between two Cloud Connectors and sets up data traffic across multiple TCP connections.

- **Note** This is only available as reference for legacy users. Zscaler's recommended deployment method is Gateway Load Balancer (GWLB), which distributes traffic across multiple Cloud Connectors and achieves high availability.

### **Starter Deployment Template with ZPA and High Availability (deprecated)**

Use the [**Starter Deployment Template with High Availability**](examples/base_2cc_zpa) to deploy your Cloud Connector in a new VPC with lambda health monitoring for failover and ZPA DNS resolver capability. This template achieves high availability between two Cloud Connectors and sets up data traffic across multiple TCP connections.

- **Note** This is only available as reference for legacy users. Zscaler's recommended deployment method is Gateway Load Balancer (GWLB), which distributes traffic across multiple Cloud Connectors and achieves high availability.

### **Starter Deployment Template with Gateway Load Balancer (GWLB)**

Use the [**Starter Deployment Template with GWLB**](examples/base_cc_gwlb) to deploy your Cloud Connector in a new VPC and to load balance traffic across multiple Cloud Connectors. Zscaler\'s recommended deployment method is Gateway Load Balancer (GWLB). GWLB distributes traffic across multiple Cloud Connectors and achieves high availability.

## **Brownfield Deployment**

Brownfield deployment templates are most applicable for production deployments and have more customization options than a \"base\"
deployment. They also do not include a bastion or workload hosts deployed. See [Modules](https://github.com/zscaler/terraform-aws-cloud-connector-modules/tree/main/examples) for the Terraform configurations for brownfield deployment.

### **Custom Deployment Template with Gateway Load Balancer (GWLB)**

Use the [**Custom Deployment template with GWLB**](examples/cc_gwlb) to deploy your Cloud Connector in a new or existing VPC and load balance traffic across multiple Cloud Connectors. Zscaler\'s recommended deployment method is Gateway Load Balancer (GWLB). GWLB distributes traffic across multiple
Cloud Connectors and achieves high availability. Optional ZPA/Route53 add-on capabilities.
