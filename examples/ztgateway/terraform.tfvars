## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment

#####################################################################################################################
##### Custom variables. Only change if required for your environment  #####
#####################################################################################################################

## 1. The name string for all ZT Gateway resources created by Terraform for Tag/Name attributes. (Default: zscc)

#name_prefix                                = "zscc"

## 2. AWS region where ZT Gateway resources will be deployed. This environment variable is automatically populated if running ZSEC script
##    and thus will override any value set here. Only uncomment and set this value if you are deploying terraform standalone. (Default: us-west-2)

#aws_region                                 = "us-west-2"

## 3. Network Configuration:

##    IPv4 CIDR configured with VPC creation. All Subnet resources (Workload, Public, ZT Endpoint, Route 53) will be created based off this prefix
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
##    Example: If you change vpc_cidr to "10.2.0.0/24", set below variables to cidrs that fit in that /24 like public_subnets = ["10.2.0.0/27","10.2.0.32/27"] etc.

#endpoint_subnets                           = ["10.x.y.z/24","10.x.y.z/24"]
#public_subnets                             = ["10.x.y.z/24","10.x.y.z/24"]
#workloads_subnets                          = ["10.x.y.z/24","10.x.y.z/24"]

## 4. Tag attribute "Owner" assigned to all resoure creation. (Default: "zscc-admin")

#owner_tag                                  = "username@company.com"

## 5a. The number of ZT Gateway Subnets to create by explicit availability zone ID
##    **** NOTE - This value will be ignored if byo_vpc / byo_subnets is set
##    **** NOTE - This value will take precedence over az_count and the preferred variable to use

#az_ids                                     = ["use1-az1" "use1-az5"]

## 5b. The number of ZT Gateway Subnets to create in sequential availability zones. Available input range 1-3 (Default: 2)
##    **** NOTE - This value will be ignored if byo_vpc / byo_subnets is set
##    #### NOTE - This value will be ignored if az_ids is set to a non-null value

#az_count                                   = 2

## 6. Zscaler provided Zero Trust Gateway Endpoint Service Name

#byo_endpoint_service_name                  = "com.amazonaws.vpce.us-east-1.vpce-svc-123456789"


#####################################################################################################################
##### Custom BYO variables. Only applicable for deployments without "base" resource requirements  #####
#####                                 E.g. "ztgateway"                                            #####
#####################################################################################################################

## 7. By default, this script will create a new AWS VPC.
##    Uncomment if you want to deploy to a VPC that already exists (true or false. Default: false)

#byo_vpc                                    = true

## 8. Provide your existing VPC ID. Only uncomment and modify if you set byo_vpc to true. (Default: null)
##     Example: byo_vpc_id = "vpc-0588ce674df615334"

#byo_vpc_id                                 = "vpc-0588ce674df615334"

## 9. By default, this script will create new AWS subnets in the VPC defined based on either var.az_ids or var.az_count.
##     Uncomment if you have existing subnets that you want to deploy to (true or false. Default: false)
##     Dependencies require in order to reference existing subnets, the corresponding VPC must also already exist.
##     Setting byo_subnet to true means byo_vpc must ALSO be set to true.

#byo_subnets                                = true

## 10. Provide your existing Subnet IDs. Only uncomment and modify if you set byo_subnets to true.
##     Subnet IDs must be added as a list with order determining assocations for resources like aws_instance, NAT GW,
##     Route Tables, etc. Provide only one subnet per Availability Zone in a VPC
##
##     Note: Subnet IDs provided should reside in one of the Zero Trust Gateway provisioned Availability Zone IDs
##
##
##     Example: byo_subnet_ids = ["subnet-05c32f4aa6bc02f8f","subnet-13b35f23y6uc36f3s"]

#byo_subnet_ids                             = ["subnet-id"]

## 11. By default, this script will create new route table resources associated to ZT Endpoint defined subnets
##     Uncomment, if you do NOT want to create new route tables (true or false. Default: true)
##     By uncommenting (setting to false) this assumes that you have an existing VPC/Subnets (byo_subnets = true)

#zs_route_table_enabled                     = false
