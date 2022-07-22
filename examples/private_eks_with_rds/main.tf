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
  cluster_name      = local.name
  cluster_version   = "1.22"
  service_ipv4_cidr = "10.143.0.0/16"
  vpc_id            = module.my_vpc.vpc_id
  subnet_ids        = module.my_vpc.private_subnets_ids

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
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1
      instance_types   = ["t3a.medium"]
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

module "rds" {
  source = "git@github.com:padok-team/terraform-aws-rds.git?ref=v2.1.0"

  ## GENERAL
  identifier = "rds-poc-library-multi-az"

  ## DATABASE
  engine              = "postgres"
  engine_version      = "13.4"
  db_parameter_family = "postgres13"
  name                = "aws_rds_instance_postgresql_db_poc_library_multi_az"
  username            = "aws_rds_instance_postgresql_user_poc_library_multi_az"

  # add access to RDS for eks nodes
  security_group_ids = [
    module.my_eks.this.eks_managed_node_groups.app.security_group_id
  ]

  parameters = [{
    name         = "application_name"
    value        = "mydb"
    apply_method = "immediate"
    },
    {
      name         = "rds.rds_superuser_reserved_connections"
      value        = 4
      apply_method = "pending-reboot"
  }]

  ## NETWORK
  subnet_ids = module.my_vpc.private_subnets_ids
  vpc_id     = module.my_vpc.vpc_id
}

################################################################################
# Supporting resources
################################################################################

module "my_vpc" {
  source = "git@github.com:padok-team/terraform-aws-network.git"

  vpc_name              = local.name
  vpc_availability_zone = ["eu-west-3a", "eu-west-3b"]

  vpc_cidr            = "10.142.0.0/16"
  public_subnet_cidr  = ["10.142.1.0/28", "10.142.2.0/28"]    # small subnets for natgateway
  private_subnet_cidr = ["10.142.64.0/18", "10.142.128.0/18"] # big subnet for EKS

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
