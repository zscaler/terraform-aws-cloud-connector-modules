# Zscaler Cloud Connector Cluster Infrastructure Setup

**Terraform configurations and modules for deploying Zscaler Cloud Connector Cluster in AWS.**

## Prerequisites (You will be prompted for AWS keys and region during deployment)

### AWS requirements
1. A valid AWS account with Administrator Access to deploy required resources
2. AWS ACCESS KEY ID
3. AWS SECRET ACCESS KEY
4. AWS Region (E.g. us-west-2)
5. Subscribe and accept terms of using Amazon Linux 2 AMI (for base deployments with workloads + bastion) at [this link](https://aws.amazon.com/marketplace/pp/prodview-zc4x2k7vt6rpu)
6. Subscribe and accept terms of using Zscaler Cloud Connector image at [this link](https://aws.amazon.com/marketplace/pp/prodview-cvzx4oiv7oljm)

### Zscaler requirements
7. A valid Zscaler Cloud Connector provisioning URL generated from the Cloud Connector Portal
8. Zscaler Cloud Connector Credentials (api key, username, password) are stored in AWS Secrets Manager

### **Terraform client requirements**
9. If executing Terraform via the "zsec" wrapper bash script, it is advised that you run from a MacOS or Linux workstation. Minimum installed application requirements to successfully from the script are:
- AWS CLI (to generate temporary session token if required)
- bash
- curl
- unzip
<br>
<br>

See: [Zscaler Cloud Connector AWS Deployment Guide](https://help.zscaler.com/cloud-connector/deploying-cloud-connector-amazon-web-services) for additional prerequisite provisioning steps.

## Deploying the cluster
(The automated tool can run only from MacOS and Linux. You can also upload all repo contents to the respective public cloud provider Cloud Shells and run directly from there).   
 
**1. Greenfield Deployments**

(Use this if you are building an entire cluster from ground up.
 Particularly useful for a Customer Demo/PoC or dev-test environment)

```
bash
cd examples
Optional: Edit the terraform.tfvars file under your desired deployment type (ie: base_1cc) to setup your Cloud Connector (Details are documented inside the file)
- ./zsec up
- enter "greenfield"
- enter <desired deployment type>
- follow prompts for any additional configuration inputs. *keep in mind, any modifications done to terraform.tfvars first will override any inputs from the zsec script*
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm
```

**Greenfield Deployment Types:**

```
Deployment Type: (base | base_1cc | base_1cc_zpa | base_2cc | base_2cc_zpa | base_cc_gwlb | base_cc_gwlb_zpa):
base: Creates 1 new VPC with 1 public subnet and 1 private/workload subnet; 1 IGW; 1 NAT Gateway; 1 Centos server workload in the private subnet routing to NAT Gateway; This does NOT deploy any actual Cloud Connectors.
1 Bastion Host in the public subnet assigned an Elastic IP and routing to the IGW; generates local key pair .pem file for ssh access
base_1cc: Base Deployment Type + Creates 1 Cloud Connector private subnet; 1 Cloud Connector VM routing to NAT Gateway; workload private subnet route repointed to service ENI of Cloud Connector
base_1cc_zpa: Everything from base_1cc Deployment Type + Creates 2 Route 53 subnets routing to service ENI of Cloud Connector; Route 53 outbound resolver endpoint; Route 53 resolver rules for ZPA
base_2cc (**deprecated**): Everything from base_1cc + Creates a second Cloud Connector in a new subnet/AZ w/ Lambda for HA failover of workload route tables
base_2cc_zpa (**deprecated**): Everything from Base_2cc + Creates 2 Route 53 subnets routing to service ENI of Cloud Connector; Route 53 outbound resolver endpoint; Route 53 resolver rules for ZPA
base_cc_gwlb: Base Deployment Type + Creates 4 Cloud Connectors (2 per subnet/AZ) routing to NAT Gateway; Gateway Load Balancer auto registering service ips to target group with health checks; VPC Endpoint Service; 2 GWLB Endpoints (1 in each Cloud Connector subnet); workload private subnet routes repointed to the GWLBE in their same AZ
base_cc_gwlb_zpa: Everything from base_cc_gwlb + Creates 2 Route 53 subnets routing to service ENI of Cloud Connector; Route 53 outbound resolver endpoint; Route 53 resolver rules for ZPA
```

**2. Brownfield Deployments**

(These templates would be most applicable for production deployments and have more customization options than a "base" deployments). They also do not include a bastion or workload hosts deployed.

```
bash
cd examples
Optional: Edit the terraform.tfvars file under your desired deployment type (ie: cc_gwlb) to setup your Cloud Connector (Details are documented inside the file)
- ./zsec up
- enter "brownfield"
- enter <desired deployment type>
- follow prompts for any additional configuration inputs. *keep in mind, any modifications done to terraform.tfvars first will override any inputs from the zsec script*
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm
```

**Brownfield Deployment Types**

```
Deployment Type: (cc_ha | cc_gwlb):
cc_ha (**deprecated**): Creates 1 new VPC with 2 public subnets and 2 Cloud Connector private subnets; 1 IGW; 2 NAT Gateways; 2 Cloud Connector VMs (1 per subnet/AZ) routing to the NAT Gateway in their same AZ; generates local key pair .pem file for ssh access; Number of Cloud Connectors and subnets deployed, ability to use existing resources (VPC, subnets, IGW, NAT Gateways), and toggle ZPA/R53 and Lambda HA failover features; generates local key pair .pem file for ssh access
cc_gwlb: All options from cc_ha + replace lambda with Gateway Load Balancer auto registering service ips to target group with health checks; VPC Endpoint Service; 1 GWLB Endpoints per Cloud Connector subnet
```

## Destroying the cluster
```
cd examples
- ./zsec destroy
- verify all resources that will be destroyed and enter "yes" to confirm
```

## Notes
```
1. For auto approval set environment variable **AUTO_APPROVE** or add `export AUTO_APPROVE=1`
2. For deployment type set environment variable **dtype** to the required deployment type or add `export dtype=base_1cc_zpa`
3. To provide new credentials or region, delete the autogenerated .zsecrc file in your current working directory and re-run zsec.
```
