terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
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

  name   = "spot_nodes"
  env    = "test"
  region = "eu-west-3"
}

# a basic example with a public EKS endpoint
module "my_eks" {
  source = "../.."

  env                                  = local.env
  region                               = local.region
  cluster_name                         = local.name
  cluster_version                      = "1.22"
  service_ipv4_cidr                    = "10.143.0.0/16"
  vpc_id                               = module.my_vpc.vpc_id
  subnet_ids                           = module.my_vpc.private_subnets_ids
  cluster_endpoint_public_access       = true                 # private access is enable by default
  cluster_endpoint_public_access_cidrs = ["46.193.107.14/32"] # restrict to your public IP

  node_groups = {
    app = {
      desired_size   = 1
      max_size       = 5
      min_size       = 1
      instance_types = ["t3a.large", "m5a.large", "m5.large"]
      capacity_type  = "SPOT"
      key_name       = aws_key_pair.ssh_key.key_name
    }
  }

  # List of roles to add to the aws-auth configmap

  # aws_auth_roles = [
  #   {
  #     rolearn  = "arn:aws:iam::66666666666:role/role1"
  #     username = "role1"
  #     groups   = ["system:masters"]
  #   },
  # ]

  tags = {
    CostCenter = "EKS"
  }
}

output "my_cluster" {
  value = module.my_eks.this
}

output "external_dns_role_arn" {
  value = module.my_eks.external_dns_role_arn
}
output "external_secret_role_arn" {
  value = module.my_eks.external_secret_role_arn
}
output "cluster_autoscaler_role_arn" {
  value = module.my_eks.cluster_autoscaler_role_arn
}

################################################################################
# Supporting resources
################################################################################

# SSM Bastion to connect to EKS trough an SSH tunnel
module "my_ssm_bastion" {
  source = "git@github.com:padok-team/terraform-aws-bastion-ssm?ref=v2.0.0"

  ssm_logging_bucket_name = aws_s3_bucket.ssm_logs.id
  security_groups         = [aws_security_group.bastion_ssm.id]
  vpc_zone_identifier     = module.my_vpc.private_subnets_ids
}

# s3 bucket for logging
resource "aws_s3_bucket" "ssm_logs" {
  bucket = "bastion-ssm-logs"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

module "my_vpc" {
  source = "git@github.com:padok-team/terraform-aws-network.git"

  vpc_name              = local.name
  vpc_availability_zone = ["eu-west-3a", "eu-west-3b"]

  vpc_cidr            = "10.144.0.0/16"
  public_subnet_cidr  = ["10.144.1.0/28", "10.144.2.0/28"]    # small subnets for natgateway
  private_subnet_cidr = ["10.144.64.0/18", "10.144.128.0/18"] # big subnet for EKS

  single_nat_gateway = true # warning : not for production !
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}_${local.env}" = "shared"
    "kubernetes.io/role/elb"                           = "1"
  }

  tags = {
    CostCenter = "Network"
  }
}
