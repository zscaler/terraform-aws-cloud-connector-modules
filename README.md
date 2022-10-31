# Zscaler Cloud Connector AWS Terraform Modules

## Description
This repository contains various modules and deployment configurations that can be used to deploy Zscaler Cloud Connector appliances to securely connect Workload to Internet and Workload to Workload communication within Amazon Web Services (AWS). The examples directory contains complete automation scripts for both greenfield/POV and brownfield/production use.

These deployment templates are intended to be fully functional and self service for both greenfield/pov as well as production use. All modules may also be utilized as design recommendation based on Zscaler's Official [Zero Trust Security for AWS Workloads Reference Architecture](https://help.zscaler.com/cloud-connector/zero-trust-security-aws-workloads-zscaler-cloud-connector).

## Prerequisites

Our Deployment scripts are leveraging Terraform v1.1.9 that includes full binary and provider support for MacOS M1 chips, but any Terraform version 0.13.7 should be generally supported.

- provider registry.terraform.io/hashicorp/aws v4.7.x
- provider registry.terraform.io/hashicorp/random v3.3.x
- provider registry.terraform.io/hashicorp/local v2.2.x
- provider registry.terraform.io/hashicorp/null v3.1.x
- provider registry.terraform.io/providers/hashicorp/tls v3.4.x

### AWS requirements
1. A valid AWS account with Administrator Access to deploy required resources
2. AWS ACCESS KEY ID
3. AWS SECRET ACCESS KEY
4. AWS Region (E.g. us-west-2)
5. Subscribe and accept terms of using Amazon Linux 2 (for base deployments with workloads + bastion) at [this link](https://aws.amazon.com/marketplace/pp/prodview-zc4x2k7vt6rpu)
6. Subscribe and accept terms of using Zscaler Cloud Connector image at [this link](https://aws.amazon.com/marketplace/pp/prodview-cvzx4oiv7oljm)

### Zscaler requirements
7. A valid Zscaler Cloud Connector provisioning URL generated from the Cloud Connector Portal
8. Zscaler Cloud Connector Credentials (api key, username, password) are stored in AWS Secrets Manager

See: [Zscaler Cloud Connector AWS Deployment Guide](https://help.zscaler.com/cloud-connector/deploying-cloud-connector-amazon-web-services) for additional prerequisite provisioning steps.

## How to deploy
Provisioning templates are available for customer use/reference to successfully deploy fully operational Cloud Connector appliances once the prerequisites have been completed. Please follow the instructions located in [examples](examples/README.md).

## Format

This repository follows the [Hashicorp Standard Modules Structure](https://www.terraform.io/registry/modules/publish):

* `modules` - All module resources utilized by and customized specifically for Cloud Connector deployments. The intent is these modules are resusable and functional for any deployment type referencing for both production or lab/testing purposes.
* `examples` - Zscaler provides fully functional deployment templates utilizing a combination of some or all of the modules published. These can utilized in there entirety or as reference templates for more advanced customers or custom deployments. For novice Terraform users, we also provide a bash script (zsec) that can be run from any Linux/Mac OS or CSP Cloud Shell that walks through all provisioning requirements as well as downloading/running an isolated teraform process. This allows Cloud Connector deployments from any supported client without having to even have Terraform installed or know how the language/syntax for running it.

## Versioning

These modules follow recommended release tagging in [Semantic Versioning](http://semver.org/). You can find each new release,
along with the changelog, on the GitHub [Releases](https://github.com/zscaler/terraform-aws-cloud-connector-modules/releases) page.

# License and Copyright

Copyright (c) 2022 Zscaler, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
