## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment


#####################################################################################################################
##### Variables 1-12 are populated automically if terraform is ran via ZSEC bash script.   ##### 
##### Modifying the variables in this file will override any inputs from ZSEC             #####
#####################################################################################################################


#####################################################################################################################
##### Cloud Init Userdata Provisioning variables  #####
#####################################################################################################################

## 1. Zscaler Cloud Connector Provisioning URL E.g. connector.zscaler.net/api/v1/provUrl?name=aws_prov_url

#cc_vm_prov_url                             = "connector.zscaler.net/api/v1/provUrl?name=aws_prov_url"

## 2. AWS Secrets Manager Secret Name from Secrets Manager E.g ZS/CC/credentials

#secret_name                                =  "ZS/CC/credentials/aws_cc_secret_name"

## 3. Cloud Connector cloud init provisioning listener port. This is required for GWLB and Health Probe deployments. 
## Uncomment and set custom probe port to a single value of 80 or any number between 1024-65535. Default is 50000.

#http_probe_port                            = 50000


#####################################################################################################################
##### Custom variables. Only change if required for your environment  #####
#####################################################################################################################

## 4. The name string for all Cloud Connector resources created by Terraform for Tag/Name attributes. (Default: zscc)

#name_prefix                                = "zscc"


## 5. AWS region where Cloud Connector resources will be deployed. This environment variable is automatically populated if running ZSEC script
##    and thus will override any value set here. Only uncomment and set this value if you are deploying terraform standalone. (Default: us-west-2)

#aws_region                                 = "us-west-2"


## 6. Cloud Connector AWS EC2 Instance size selection. Uncomment ccvm_instance_type line with desired vm size to change.
##    (Default: m5.large)

#ccvm_instance_type                         = "t3.medium"
#ccvm_instance_type                         = "m5.large"
#ccvm_instance_type                         = "c5.large"
#ccvm_instance_type                         = "c5a.large"
#ccvm_instance_type                         = "m5.2xlarge"
#ccvm_instance_type                         = "c5.2xlarge"
#ccvm_instance_type                         = "m5.4xlarge"
#ccvm_instance_type                         = "c5.4xlarge"


## 7. Cloud Connector Instance size selection. Uncomment cc_instance_size line with desired vm size to change
##    (Default: "small") 
##    **** NOTE - There is a dependency between ccvm_instance_type and cc_instance_size selections ****
##    If size = "small" any supported EC2 instance type can be deployed, but "m5/c5.large" is ideal
##    If size = "medium" only 2xlarge and up EC2 instance types can be deployed
##    If size = "large" only 4xlarge EC2 instane types can be deployed 
##    **** NOTE - medium and large cc_instance_size is only supported with GWLB deployments. Legacy HA/Lambda deployments must be small.

#cc_instance_size                           = "small"
#cc_instance_size                           = "medium"
#cc_instance_size                           = "large" 


## 8. Network Configuration:

##    IPv4 CIDR configured with VPC creation. All Subnet resources (Workload, Public, Cloud Connector, Route 53) will be created based off this prefix
##    /24 subnets are created assuming this cidr is a /16. If you require creating a VPC smaller than /16, you may need to explicitly define all other 
##     subnets via public_subnets, workload_subnets, cc_subnets, and route53_subnets variables

##    Note: This variable only applies if you let Terraform create a new VPC. Custom deployment with byo_vpc enabled will ignore this

#vpc_cidr                                   = "10.1.0.0/16"

##    Subnet space. (Minimum /28 required. Default is null). If you do not specify subnets, they will automatically be assigned based on the default cidrsubnet
##    creation within the VPC CIDR block. Uncomment and modify if byo_vpc is set to true but byo_subnets is left false meaning you want terraform to create 
##    NEW subnets in that existing VPC. OR if you choose to modify the vpc_cidr from the default /16 so a smaller CIDR, you may need to edit the below variables 
##    to accommodate that address space.

##    ***** Note *****
##    It does not matter how many subnets you specify here. this script will only create in order 1 or as many as defined in the az_count variable
##    Default/Minumum: 1 - Maximum: 3
##    Example: If you change vpc_cidr to "10.2.0.0/24", set below variables to cidrs that fit in that /24 like cc_subnets = ["10.2.0.0/27","10.2.0.32/27"] etc.

#public_subnets                             = ["10.x.y.z/24","10.x.y.z/24"]
#cc_subnets                                 = ["10.x.y.z/24","10.x.y.z/24"]
#route53_subnets                            = ["10.x.y.z/24","10.x.y.z/24"]


## 9. Number of Workload VMs to be provisioned in the workload subnet. Only limitation is available IP space
##    in subnet configuration. Only applicable for "base" deployment types. Default workload subnet is /24 so 250 max

#workload_count                             = 2


## 10. Tag attribute "Owner" assigned to all resoure creation. (Default: "zscc-admin")

#owner_tag                                  = "username@company.com"


## 11. By default, Cloud Connectors are configured with a callhome IAM policy enabled. This is recommended for production deployments
##     The policy creation itself does not provide any authentication/authorization access. IAM details are still required to be provided
##     to Zscaler in order to establish a trust relationship. Uncomment if you do not want this policy created. (Default: true)

#cc_callhome_enabled                        = false


## 12. By default, this script will apply 1 Security Group per Cloud Connector instance. 
##     Uncomment if you want to use the same Security Group for ALL Cloud Connectors (true or false. Default: false)

#reuse_security_group                       = true


## 13. By default, this script will apply 1 IAM Role/Instance Profile per Cloud Connector instance. 
##     Uncomment if you want to use the same IAM Role/Instance Profile for ALL Cloud Connectors (true or false. Default: false)

#reuse_iam                                  = true


## 14. By default, terraform will always query the AWS Marketplace for the latest Cloud Connector AMI available.
##     This variable is provided if a customer desires to override or retain an old ami for existing deployments rather than upgrading and forcing a replacement. 
##     It is also inputted as a list to facilitate if a customer desired to manually upgrade only select CCs deployed based on the cc_count index

##     Note: Customers should NOT be hard coding AMI IDs as Zscaler recommendation is to always be deploying/running the latest version.
##           Leave this variable commented out unless you are absolutely certain why/that you need to set it and only temporarily.

#ami_id                                     = ["ami-123456789"]

#####################################################################################################################
##### ZPA/Route 53 specific variables #####
#####################################################################################################################

## 15. By default, ZPA dependent resources are not created. Uncomment if you want to enable ZPA configuration in your VPC
##     Enabling will create 1x dedicated subnet per Cloud Connector availability zones in the VPC with Route Tables pointing
##     default route to the local AZ GWLB Endpoint. Module will also create a resolver endpoint and rules per the domains
##     specified in variable "domain_names". (Default: false)

#zpa_enabled                                = true

## 16. Provide the domain names you want Route53 to redirect to Cloud Connector for ZPA interception. Only applicable for base + zpa or zpa_enabled = true
##     deployment types where Route53 subnets, Resolver Rules, and Outbound Endpoints are being created. Two example domains are populated to show the 
##     mapping structure and syntax. ZPA Module will read through each to create a resolver rule per domain_name entry. Ucomment domain_names variable and
##     add any additional appsegXX mappings as needed.

#domain_names = {
#  appseg1 = "app1.com"
#  appseg2 = "app2.com"
#}


#####################################################################################################################
##### Custom BYO variables. Only applicable for deployments without "base" resource requirements  #####
#####                                 E.g. "cc_ha"                                                #####
#####################################################################################################################

## 17. By default, this script will create a new AWS VPC.
##     Uncomment if you want to deploy all resources to a VPC that already exists (true or false. Default: false)

#byo_vpc                                    = true


## 18. Provide your existing VPC ID. Only uncomment and modify if you set byo_vpc to true. (Default: null)
##     Example: byo_vpc_id = "vpc-0588ce674df615334"

#byo_vpc_id                                 = "vpc-0588ce674df615334"


## 19. By default, this script will create new AWS subnets in the VPC defined based on az_count.
##     Uncomment if you want to deploy all resources to subnets that already exist (true or false. Default: false)
##     Dependencies require in order to reference existing subnets, the corresponding VPC must also already exist.
##     Setting byo_subnet to true means byo_vpc must ALSO be set to true.

#byo_subnets                                = true


## 20. Provide your existing Cloud Connector private subnet IDs. Only uncomment and modify if you set byo_subnets to true.
##     Subnet IDs must be added as a list with order determining assocations for resources like aws_instance, NAT GW,
##     Route Tables, etc. Provide only one subnet per Availability Zone in a VPC
##
##     ##### This script will create Route Tables with default 0.0.0.0/0 next-hop to the corresponding NAT Gateways
##     ##### that are created or exists in the VPC Public Subnets. If you already have CC Subnets created, disassociate
##     ##### any route tables to them prior to deploying this script.
##
##     Example: byo_cc_subnet_ids = ["subnet-05c32f4aa6bc02f8f","subnet-13b35f23y6uc36f3s"]

#byo_subnet_ids                             = ["subnet-id"]


## 21. By default, this script will create a new Internet Gateway resource in the VPC.
##     Uncomment if you want to utlize an IGW that already exists (true or false. Default: false)
##     Dependencies require in order to reference an existing IGW, the corresponding VPC must also already exist.
##     Setting byo_igw to true means byo_vpc must ALSO be set to true.

#byo_igw                                    = true


## 22. Provide your existing Internet Gateway ID. Only uncomment and modify if you set byo_igw to true.
##     Example: byo_igw_id = "igw-090313c21ffed44d3"

#byo_igw_id                                 = "igw-090313c21ffed44d3"


## 23. By default, this script will create new Public Subnets, and NAT Gateway w/ Elastic IP in the VPC defined or selected.
##     It will also create a Route Table forwarding default 0.0.0.0/0 next hop to the Internet Gateway that is created or defined 
##     based on the byo_igw variable and associate with the public subnet(s)
##     Uncomment if you want to deploy Cloud Connectors routing to NAT Gateway(s)/Public Subnet(s) that already exist (true or false. Default: false)
##     
##     Setting byo_ngw to true means no additional Public Subnets, Route Tables, or Elastic IP resources will be created

#byo_ngw                                    = true


## 24. Provide your existing NAT Gateway IDs. Only uncomment and modify if you set byo_cc_subnet to true
##     NAT Gateway IDs must be added as a list with order determining assocations for the CC Route Tables (cc-rt)
##     nat_gateway_id next hop
##
##     ***** Note 1 *****
##     This script will create Route Tables with default 0.0.0.0/0 next-hop to the corresponding NAT Gateways
##     whether they are created or already exist in the VPC Public Subnets. If you already have CC Subnets created, do not associate
##     any route tables to them.
##
##     ***** Note 2 *****
##     CC Route Tables will loop through all available NAT Gateways whether created via az_count variable or defined
##     below with existing IDs. If bringing your own NAT Gateways with multiple subnets with a desire to maintain zonal
##     affinity ensure you enter the list of NAT GW IDs in order of 1. if creating CC subnets az_count will 
##     go in order az1, az2, etc. 2. if byo_subnet_ids, map this list NAT Gateway ID-1 to Subnet ID-1, etc.
##     
##     Example: byo_ngw_ids = ["nat-0e1351f3e8025a30e","nat-0e98fc3d8e09ed0e9"]

#byo_ngw_ids                                = ["nat-id"]


## 25. By default, this script will create new IAM roles, policy, and Instance Profiles for the Cloud Connector
##     Uncomment if you want to use your own existing IAM Instance Profiles (true or false. Default: false)

#byo_iam                      = true


## 26. Provide your existing Instance Profile resource names. Only uncomment and modify if you set byo_iam to true

##    Example: byo_iam_instance_profile_id     = ["instance-profile-1","instance-profile-2"]

#byo_iam_instance_profile_id                = ["instance-profile-1"]


## 27. By default, this script will create new Security Groups for the Cloud Connector mgmt and service interfaces
##     Uncomment if you want to use your own existing SGs (true or false. Default: false)

#byo_security_group                         = true


## 28. Provide your existing Security Group resource names. Only uncomment and modify if you set byo_security_group to true

##    Example: byo_mgmt_security_group_id     = ["mgmt-sg-1","mgmt-sg-2"]
##    Example: byo_service_security_group_id  = ["service-sg-1","service-sg-2"]

#byo_mgmt_security_group_id                 = ["mgmt-sg-1"]
#byo_service_security_group_id              = ["service-sg-1"]

#####################################################################################################################
##### Custom BYO variables. Only applicable for Lambda (non-GWLB) deployments without "base"       #####
##### resource requirements for Workload Route Table swaps. E.g. "cc_ha"                       #####
#####                                     **** Note ****                                           #####
##### Providing Private Workload and/or TGW Attachment Route Tables implies that the VPC and       #####
##### subnets already exist. Therefore, you must provide at least byo_vpc information              #####
#####################################################################################################################

## 29. Provide your existing Workload Route Table IDs. Route Table IDs must be added as a list and should be paired to
##     the primary Cloud Connector each Route Table would be forwarding traffic to in normal operation
##
##     Example: 
##     workload_route_table_ids_to_cc_1 = ["rtb-01b395545d8701313","rtb-03b7006dc062b8132"]
##     workload_route_table_ids_to_cc_2 = ["rtb-038790126cabc8e6a","rtb-02afb810457c4fb43"]
##
##     All Route Tables entered for workload_route_table_ids_to_cc_1 should be pointing to the Cloud Connector defined
##     in cc-lambda module cc_vm1_id variable. workload_route_table_ids_to_cc_2 Route Tables point to cc_vm2_id.
##     Route Table IDs can be configured in advanced. You will just need to add the respective service ENIs to the 
##     0.0.0.0/0 route for lambda to pick up.

#workload_route_table_ids_to_cc_1           = ["rtb-1-az1","rtb-2-az1"]

#workload_route_table_ids_to_cc_2           = ["rtb-1-az2","rtb-2-az2"]
