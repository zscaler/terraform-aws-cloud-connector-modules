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

## The number of unique ZT Gateway Subnets to create. Options 5a OR 5b exist, but it is highly recommended to utilize option 5a

## 5a. By explicit availability zone ID:
##    **** NOTE - This value will be ignored if byo_vpc / byo_subnets is set
##    **** NOTE - This value will take precedence over az_count and is the preferred variable to use for granularity and compatibility

#az_ids                                     = ["use1-az1" "use1-az5"]

## 5b. By lookup of currently available and sequential availability zones. Available input range 1-3 (Default: 2)
##    **** NOTE - This value will be ignored if byo_vpc / byo_subnets is set
##    #### NOTE - This value will be ignored if az_ids is set to a non-null value

#az_count                                   = 2

## 6. Zscaler provided Zero Trust Gateway Endpoint Service Name

#byo_endpoint_service_name                  = "com.amazonaws.vpce.us-east-1.vpce-svc-123456789"
