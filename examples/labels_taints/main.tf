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

  name   = "labels_taints"
  env    = "test"
  region = "eu-west-3"
}

# a basic example with a public EKS endpoint
# private endpoint is enable by default
# don't forget that your node need external access (AWS API) to register properly on EKS
module "my_eks" {
  source = "../.."

  env                                  = local.env
  region                               = local.region
  cluster_name                         = local.name # cluster name result will be => ${local.name}_${local.env}
  cluster_version                      = "1.21"
  service_ipv4_cidr                    = "10.143.0.0/16"
  vpc_id                               = module.my_vpc.vpc_id
  subnets                              = module.my_vpc.private_subnets_ids
  cluster_endpoint_public_access       = true                 # private access is enable by default
  cluster_endpoint_public_access_cidrs = ["46.193.107.14/32"] # restrict to your public IP

  node_groups = {
    pool_api = {
      desired_capacity = 2
      max_capacity     = 10
      min_capacity     = 1
      instance_types   = ["c5a.xlarge"]

      # taint and labels for deployment, sts, etc
      k8s_labels = {
        nodetype = "api"
      }
      taints = [
        {
          key    = "dedicated"
          value  = "api"
          effect = "NO_SCHEDULE"
        }
      ]
      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }

      additional_tags = {
        CostCenterService = "api"
      }
    },
    pool_back = {
      desired_capacity = 2
      max_capacity     = 7
      min_capacity     = 1
      instance_types   = ["r5a.xlarge"]

      # taint and labels for deployment, sts, etc
      k8s_labels = {
        nodetype = "back"
      }
      taints = [
        {
          key    = "dedicated"
          value  = "back"
          effect = "NO_SCHEDULE"
        }
      ]
      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }

      additional_tags = {
        CostCenterService = "back"
      }
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

################################################################################
# Supporting resources
################################################################################

module "my_vpc" {
  source = "git@github.com:padok-team/terraform-aws-network.git"

  vpc_name              = local.name
  vpc_availability_zone = ["eu-west-3a", "eu-west-3b"]

  vpc_cidr            = "10.145.0.0/16"
  public_subnet_cidr  = ["10.145.1.0/28", "10.145.2.0/28"]    # small subnets for natgateway
  private_subnet_cidr = ["10.145.64.0/18", "10.145.128.0/18"] # big subnet for EKS

  single_nat_gateway = true # warning : not for production !

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}_${local.env}" = "shared"
    "kubernetes.io/role/elb"                           = "1"
  }

  tags = {
    CostCenter = "Network"
  }
}