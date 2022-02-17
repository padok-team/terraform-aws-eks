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

  name   = "basic_private"
  env    = "test"
  region = "eu-west-3"
}

# a basic example with a public EKS endpoint
# private endpoint is enable by default
# don't forget that your node need external access (AWS API) to register properly on EKS
module "my_eks" {
  source = "../.."

  env               = local.env
  region            = local.region
  cluster_name      = local.name # cluster name result will be => ${local.name}_${local.env}
  cluster_version   = "1.21"
  service_ipv4_cidr = "10.143.0.0/16"
  vpc_id            = module.my_vpc.vpc_id
  subnet_ids        = module.my_vpc.private_subnets_ids

  # allow SSM Bastion to connect to API Server
  cluster_security_group_additional_rules = {
    allow_bastion_access_to_eks_api_server = {
      description                = "Allow bastion to access EKS API server"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_node_security_group = false
      source_security_group_id   = aws_security_group.bastion_ssm.id
    }
  }

  node_groups = {
    app = {
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      instance_types = ["t3a.medium"]
    }
  }

  tags = {
    CostCenter = "EKS"
  }
}

output "my_cluster" {
  value = module.my_eks.this
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

# SSM Bastion to connect to EKS trough an SSH tunnel
module "my_ssm_bastion" {
  source = "git@github.com:padok-team/terraform-aws-bastion-ssm"

  ssm_logging_bucket_name = aws_s3_bucket.ssm_logs.id
  security_groups         = [aws_security_group.bastion_ssm.id]
  vpc_zone_identifier     = module.my_vpc.private_subnets_ids
}

output "ssm_key" {
  value     = module.my_ssm_bastion.ssm_private_key
  sensitive = true
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

# create a security group for the bastion
resource "aws_security_group" "bastion_ssm" {
  name        = "bastion_ssm"
  description = "Allow output for bastion"
  vpc_id      = module.my_vpc.vpc_id

  # allow access to SSM endpoints
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
