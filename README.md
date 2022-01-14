# AWS EKS Terraform module

Terraform module which creates EKS resources on AWS. This module is an abstraction of the [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) by [@brandoconnor](https://registry.terraform.io/namespaces/brandoconnor).

## User Stories for this module

- AAOps I can deploy a simple HA cluster with filtered public access
- AAOps I can deploy a simple HA cluster with only private access
- AAOps I can deploy a HA cluster with different node pools with labels and taints

## Usage

```hcl
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
  }
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Env         = local.env
      Region      = local.region
      OwnedBy     = "Padok"
      ManagedByTF = true
    }
  }
}

# some variables to make life easier
locals {

  name   = "my_cluster"
  env    = "staging"
  region = "eu-west-3"
}

# a basic example with a public EKS endpoint
module "my_eks" {
  source = "git@github.com:padok-team/terraform-aws-eks.git?ref=v0.1.0"

  env                                  = local.env
  region                               = local.region
  cluster_name                         = local.name # cluster name result will be => ${local.name}_${local.env}
  cluster_version                      = "1.21"
  service_ipv4_cidr                    = "10.143.0.0/16"
  vpc_id                               = module.my_vpc.vpc_id
  subnets                              = module.my_vpc.private_subnets_id
  cluster_endpoint_public_access       = true                 # private access is enable by default
  cluster_endpoint_public_access_cidrs = # restrict to your public IP, need to provide a list

  node_groups = {
    app = {
      desired_capacity = 1
      max_capacity     = 5
      min_capacity     = 1
      instance_types   = ["t3a.medium"]
    }
  }

  tags = {
    CostCenter = "EKS"
  }

  # ⚠️ Very important note ⚠️
  # force dependency on vpc because we need natgateway & route table to be up before
  # starting our node pool because without appriopriate route, node can't talk
  # to AWS API and can't auht on EKS API Server
  depends_on = [
    module.my_vpc
  ]
}

################################################################################
# Supporting resources
################################################################################

module "my_vpc" {
  source = "git@github.com:padok-team/terraform-aws-network.git?ref=0.1.0"

  vpc_name              = local.name
  vpc_availability_zone = ["eu-west-3a", "eu-west-3b"]

  vpc_cidr            = "10.142.0.0/16"
  public_subnet_cidr  = ["10.142.1.0/28", "10.142.2.0/28"]    # small subnets for natgateway
  private_subnet_cidr = ["10.142.64.0/18", "10.142.128.0/18"] # big subnet for EKS

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}_${local.env}" = "shared"
    "kubernetes.io/role/elb"                           = "1"
  }

  tags = {
    CostCenter = "Network"
  }
}
```

## Examples

- [A HA Cluster with a public endpoint](examples/basic_public/main.tf)
- [A HA Cluster with only a prvate endpoint](examples/basic_private/main.tf)
- [A HA Cluster with labels and taints on nodes](examples/labels_taints/main.tf)
- [Use spot instance for my nodes with custom SSH Key](examples/spot_nodes/main.tf)
- [Use custom IAM roles for nodes and cluster](examples/custom_iam.tf)

<!-- BEGIN_TF_DOCS -->
## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 17.22.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | EKS version | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region name | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for EKS | `string` | n/a | yes |
| <a name="input_cluster_create_security_group"></a> [cluster\_create\_security\_group](#input\_cluster\_create\_security\_group) | Indicate wether a new security group must be created or not | `bool` | `true` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) | `list(string)` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Enable API Server private endpoint | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Enable API Server public endpoint | `bool` | `false` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint. | `list(string)` | <pre>[<br>  "192.168.0.1/32"<br>]</pre> | no |
| <a name="input_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#input\_cluster\_iam\_role\_name) | IAM role name for the cluster. If manage\_cluster\_iam\_resources is set to false, set this to reuse an existing IAM role. If manage\_cluster\_iam\_resources is set to true, set this to force the created role name. | `string` | `""` | no |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | If provided, the EKS cluster will be attached to this security group. If not given, a security group will be created with necessary ingress/egress to work with the workers | `string` | `""` | no |
| <a name="input_kms_etcd"></a> [kms\_etcd](#input\_kms\_etcd) | KMS key ARN for etcd encryption | `string` | `null` | no |
| <a name="input_manage_cluster_iam_resources"></a> [manage\_cluster\_iam\_resources](#input\_manage\_cluster\_iam\_resources) | Whether to let the module manage cluster IAM resources. If set to false, cluster\_iam\_role\_name must be specified. | `bool` | `true` | no |
| <a name="input_manage_worker_iam_resources"></a> [manage\_worker\_iam\_resources](#input\_manage\_worker\_iam\_resources) | Whether to let the module manage worker IAM resources. If set to false, iam\_role\_arn must be specified for nodes. | `bool` | `true` | no |
| <a name="input_node_group_ami_id"></a> [node\_group\_ami\_id](#input\_node\_group\_ami\_id) | ID of the AMI to use on the EKS Nodes | `string` | `null` | no |
| <a name="input_node_group_ami_type"></a> [node\_group\_ami\_type](#input\_node\_group\_ami\_type) | AMI type for EKS Nodes | `string` | `null` | no |
| <a name="input_node_group_disk_size"></a> [node\_group\_disk\_size](#input\_node\_group\_disk\_size) | EBS disk size for node group | `number` | `20` | no |
| <a name="input_node_group_iam_role_arn"></a> [node\_group\_iam\_role\_arn](#input\_node\_group\_iam\_role\_arn) | IAM role ARN for workers | `string` | `null` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Map of map of node groups to create. See `node_groups` module's documentation for more details | `any` | `{}` | no |
| <a name="input_service_ipv4_cidr"></a> [service\_ipv4\_cidr](#input\_service\_ipv4\_cidr) | service ipv4 cidr for the kubernetes cluster | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A list of subnets to place the EKS cluster and workers within. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | `{}` | no |
| <a name="input_worker_additional_security_group_ids"></a> [worker\_additional\_security\_group\_ids](#input\_worker\_additional\_security\_group\_ids) | A list of additional security group ids to attach to worker instances | `list(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

### Inputs for node_groups

[All options available in the sub module](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/node_groups)

## Outputs

Ouputs are the same than [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) module.

## Next steps

  - An example with encrypted EBS
  - An example with custom AMI

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

```text
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
```
