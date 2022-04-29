# AWS EKS Terraform module

Terraform module which creates EKS resources on AWS. This module is an abstraction of the [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) by [@brandoconnor](https://registry.terraform.io/namespaces/brandoconnor).

## User Stories for this module

- AAOps I can deploy a simple HA cluster with filtered public access
- AAOps I can deploy a simple HA cluster with only private access
- AAOps I can deploy a HA cluster with different node pools with labels and taints

## Changelog / Importants notes

### Migration from 0.3.0 to 0.4.0

We are now using [EKS module v18.17.0](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) as source module. This version introduce a lot of breaking changes. Before upgrading to v0.4.0 please have a look at the [PR](https://github.com/padok-team/terraform-aws-eks/pull/16/files), the documentation and be carreful before applying your changes.

## Usage

```hcl
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63.0, < 4.0.0"
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
  source = "git@github.com:padok-team/terraform-aws-eks.git"

  env                                  = local.env
  region                               = local.region
  cluster_name                         = local.name
  cluster_version                      = "1.21"
  service_ipv4_cidr                    = "10.143.0.0/16"
  vpc_id                               = module.my_vpc.vpc_id
  subnet_ids                           = module.my_vpc.private_subnets_ids_id
  cluster_endpoint_public_access       = true # private access is enable by default
  cluster_endpoint_public_access_cidrs = ["8.8.8.8/32"] # restrict to your public IP, need to provide a list

  node_groups = {
    app = {
      desired_size = 1
      max_size     = 2
      min_size     = 1
      instance_types   = ["t3a.medium"]
    }
  }

  tags = {
    CostCenter = "EKS"
  }
}

################################################################################
# Supporting resources
################################################################################

module "my_vpc" {
  source = "git@github.com:padok-team/terraform-aws-network.git"

  vpc_name              = local.name
  vpc_availability_zone = ["eu-west-3a", "eu-west-3b"]

  vpc_cidr            = "10.152.0.0/16"
  public_subnet_cidr  = ["10.152.1.0/28", "10.152.2.0/28"]    # small subnets for natgateway
  private_subnet_cidr = ["10.152.64.0/18", "10.152.128.0/18"] # big subnet for EKS

  single_nat_gateway = true # warning : not for production !

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
- [A HA Cluster with only a private endpoint (bonus SSM Bastion)](examples/basic_private/main.tf)
- [A HA Cluster with labels and taints on nodes](examples/labels_taints/main.tf)
- [Use spot instance for my nodes with custom SSH Key](examples/spot_nodes/main.tf)
- [Use custom IAM roles for nodes and cluster](examples/custom_iam/main.tf)
- [Deploy an EKS cluster with an RDS instance and access allowed from EKS nodes](examples/private_eks_with_rds/main.tf)

<!-- BEGIN_TF_DOCS -->

## Modules

| Name                                            | Source                        | Version |
| ----------------------------------------------- | ----------------------------- | ------- |
| <a name="module_this"></a> [this](#module_this) | terraform-aws-modules/eks/aws | 18.17.0 |

## Inputs

| Name                                                                                                                                                   | Description                                                                                                                                                                                                | Type           | Default                                                                                                 | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_cluster_name"></a> [cluster_name](#input_cluster_name)                                                                                  | Name of the EKS cluster                                                                                                                                                                                    | `string`       | n/a                                                                                                     |   yes    |
| <a name="input_cluster_version"></a> [cluster_version](#input_cluster_version)                                                                         | EKS version                                                                                                                                                                                                | `string`       | n/a                                                                                                     |   yes    |
| <a name="input_env"></a> [env](#input_env)                                                                                                             | Environment name                                                                                                                                                                                           | `string`       | n/a                                                                                                     |   yes    |
| <a name="input_region"></a> [region](#input_region)                                                                                                    | AWS region name                                                                                                                                                                                            | `string`       | n/a                                                                                                     |   yes    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                                                                    | VPC ID for EKS                                                                                                                                                                                             | `string`       | n/a                                                                                                     |   yes    |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch_log_group_kms_key_id](#input_cloudwatch_log_group_kms_key_id)                         | KMS key used to encrypt the cluster Cloudwatch logs                                                                                                                                                        | `string`       | `""`                                                                                                    |    no    |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch_log_group_retention_in_days](#input_cloudwatch_log_group_retention_in_days)    | Retention duration in days of the cluster Cloudwatch logs                                                                                                                                                  | `number`       | `90`                                                                                                    |    no    |
| <a name="input_cluster_enabled_log_types"></a> [cluster_enabled_log_types](#input_cluster_enabled_log_types)                                           | A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) | `list(string)` | <pre>[<br> "api",<br> "audit",<br> "authenticator",<br> "controllerManager",<br> "scheduler"<br>]</pre> |    no    |
| <a name="input_cluster_endpoint_private_access"></a> [cluster_endpoint_private_access](#input_cluster_endpoint_private_access)                         | Enable API Server private endpoint                                                                                                                                                                         | `bool`         | `true`                                                                                                  |    no    |
| <a name="input_cluster_endpoint_public_access"></a> [cluster_endpoint_public_access](#input_cluster_endpoint_public_access)                            | Enable API Server public endpoint                                                                                                                                                                          | `bool`         | `false`                                                                                                 |    no    |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster_endpoint_public_access_cidrs](#input_cluster_endpoint_public_access_cidrs)          | List of CIDR blocks which can access the Amazon EKS public API server endpoint.                                                                                                                            | `list(string)` | <pre>[<br> "0.0.0.0/0"<br>]</pre>                                                                       |    no    |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster_security_group_additional_rules](#input_cluster_security_group_additional_rules) | List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source                      | `any`          | `{}`                                                                                                    |    no    |
| <a name="input_cluster_security_group_id"></a> [cluster_security_group_id](#input_cluster_security_group_id)                                           | If provided, the EKS cluster will be attached to this security group. If not given, a security group will be created with necessary ingress/egress to work with the workers                                | `string`       | `""`                                                                                                    |    no    |
| <a name="input_create_cluster_security_group"></a> [create_cluster_security_group](#input_create_cluster_security_group)                               | Indicate wether a new security group must be created or not                                                                                                                                                | `bool`         | `true`                                                                                                  |    no    |
| <a name="input_create_iam_role"></a> [create_iam_role](#input_create_iam_role)                                                                         | Determines whether a an IAM role is created or to use an existing IAM role                                                                                                                                 | `bool`         | `true`                                                                                                  |    no    |
| <a name="input_create_node_security_group"></a> [create_node_security_group](#input_create_node_security_group)                                        | Whether to create a security group for the workers or attach the workers to `worker_security_group_id`.                                                                                                    | `bool`         | `true`                                                                                                  |    no    |
| <a name="input_custom_node_group_defaults"></a> [custom_node_group_defaults](#input_custom_node_group_defaults)                                        | Map of custom default parameters for node groups                                                                                                                                                           | `any`          | `{}`                                                                                                    |    no    |
| <a name="input_enable_secrets_encryption"></a> [enable_secrets_encryption](#input_enable_secrets_encryption)                                           | Enable secret encryption with a KMS key                                                                                                                                                                    | `bool`         | `true`                                                                                                  |    no    |
| <a name="input_etcd_kms_arn"></a> [etcd_kms_arn](#input_etcd_kms_arn)                                                                                  | KMS key ARN for etcd encryption                                                                                                                                                                            | `string`       | `null`                                                                                                  |    no    |
| <a name="input_iam_role_arn"></a> [iam_role_arn](#input_iam_role_arn)                                                                                  | IAM role name for the cluster.                                                                                                                                                                             | `string`       | `null`                                                                                                  |    no    |
| <a name="input_iam_role_use_name_prefix"></a> [iam_role_use_name_prefix](#input_iam_role_use_name_prefix)                                              | Determines whether the IAM role name (`iam_role_name`) is used as a prefix                                                                                                                                 | `string`       | `true`                                                                                                  |    no    |
| <a name="input_node_group_ami_id"></a> [node_group_ami_id](#input_node_group_ami_id)                                                                   | ID of the AMI to use on the EKS Nodes                                                                                                                                                                      | `string`       | `null`                                                                                                  |    no    |
| <a name="input_node_group_ami_type"></a> [node_group_ami_type](#input_node_group_ami_type)                                                             | AMI type for EKS Nodes                                                                                                                                                                                     | `string`       | `null`                                                                                                  |    no    |
| <a name="input_node_group_disk_size"></a> [node_group_disk_size](#input_node_group_disk_size)                                                          | EBS disk size for node group                                                                                                                                                                               | `number`       | `20`                                                                                                    |    no    |
| <a name="input_node_group_iam_role_arn"></a> [node_group_iam_role_arn](#input_node_group_iam_role_arn)                                                 | IAM role ARN for workers                                                                                                                                                                                   | `string`       | `null`                                                                                                  |    no    |
| <a name="input_node_groups"></a> [node_groups](#input_node_groups)                                                                                     | Map of map of node groups to create. See `node_groups` module's documentation for more details                                                                                                             | `any`          | `{}`                                                                                                    |    no    |
| <a name="input_node_security_group_id"></a> [node_security_group_id](#input_node_security_group_id)                                                    | If provided, all workers will be attached to this security group. If not given, a security group will be created with necessary ingress/egress to work with the EKS cluster.                               | `string`       | `""`                                                                                                    |    no    |
| <a name="input_service_ipv4_cidr"></a> [service_ipv4_cidr](#input_service_ipv4_cidr)                                                                   | service ipv4 cidr for the kubernetes cluster                                                                                                                                                               | `string`       | `null`                                                                                                  |    no    |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)                                                                                        | A list of subnet IDs to place the EKS cluster and workers within.                                                                                                                                          | `list(string)` | `[]`                                                                                                    |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                                          | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only.                                                                            | `map(string)`  | `{}`                                                                                                    |    no    |

## Outputs

| Name                                            | Description                |
| ----------------------------------------------- | -------------------------- |
| <a name="output_this"></a> [this](#output_this) | All ouputs from the module |

<!-- END_TF_DOCS -->

### Inputs for node_groups

Note: once deployed, change on `desired_size` will not be reflected in the cluster because we assume that you will use [cluster autoscaler](https://github.com/kubernetes/autoscaler/) to scale the nodes up and down.

## Outputs

Ouputs are the same than [terraform-aws-modules/eks/aws](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v17.22.0) module.

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
