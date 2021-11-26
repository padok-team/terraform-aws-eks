
################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.22.0"

  create_eks      = true
  cluster_name    = "${var.cluster_name}_${var.env}"
  cluster_version = var.cluster_version

  # control plan logs
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # network config
  vpc_id                               = var.vpc_id
  subnets                              = var.subnets
  cluster_service_ipv4_cidr            = var.service_ipv4_cidr
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # endpoint config
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  # secret encryption
  cluster_encryption_config = [
    {
      provider_key_arn = local.etcd_kms
      resources        = ["secrets"]
    }
  ]

  # Managed Node Groups
  node_groups_defaults = {
    ami_type  = var.node_group_ami_type
    disk_size = var.node_group_disk_size
  }

  node_groups = var.node_groups

  # aws auth & kubeconfig
  manage_aws_auth  = false
  write_kubeconfig = false

  # tagging
  tags = var.tags
}

################################################################################
# KMS for encrypting secrets
################################################################################

locals {
  etcd_kms = var.kms_etcd != null ? var.kms_etcd : aws_kms_key.eks[0].arn
}

resource "aws_kms_key" "eks" {
  count = var.kms_etcd != null ? 0 : 1

  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

