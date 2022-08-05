## 0.1.0 (July 25, 2022) 
* github release refactor
* zsec update for terraform support up to 1.1.9 and aws provider 4.7.x
* zsec updated with mac m1 option for terraform arm64 version download
* modules renamed for granularity and consistency
* CC IAM and Security Group resources broken out to individual child modules
* Support for reusing the same IAM and Security Group resources for all CC VMs.
* Bring your own IAM Instance Profile and Security Groups available for brownfield/custom deployments
* terraform-zscc-lambda-aws module - fix for lambda deployments containing only 1 CC subnet
* move provider details to versions.tf
* added TF_DATA_DIR to zsec and backend.tf to each deployment type to maintain root path as "examples/" directory for all deployments
* renamed cc_custom to cc_ha
* renamed cc_gwlb_custom to cc_gwlb
* added bastion source ssh security group option
* add auto acceptance and allowed_principals capability to terraform-zscc-gwlbendpoint-aws module. Default to auto accept restricting to user's Account ID