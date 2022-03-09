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

  node_groups = {
    app = {
      desired_size   = 1
      max_size       = 5
      min_size       = 1
      instance_types = ["t3a.medium"]
    }
  }

  tags = {
    CostCenter = "EKS"
  }

  # ⚠️ Very important note ⚠️
  # force dependency on vpc because we need natgateway & route table to be up before
  # starting our node pool because without appriopriate route, node can't talk
  # to AWS API and can't auth on EKS API Server
  depends_on = [
    module.my_vpc
  ]
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
