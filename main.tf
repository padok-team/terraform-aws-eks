################################################################################
# EKS Module
################################################################################

module "this" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.22.0"

  create_eks      = true
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  manage_cluster_iam_resources = var.manage_cluster_iam_resources
  cluster_iam_role_name        = var.cluster_iam_role_name

  # Control plane logs
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  cluster_log_kms_key_id        = var.cluster_log_kms_key_id
  cluster_log_retention_in_days = var.cluster_log_retention_in_days

  # Network config
  vpc_id                               = var.vpc_id
  subnets                              = var.subnets
  cluster_service_ipv4_cidr            = var.service_ipv4_cidr
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Security groups
  cluster_create_security_group        = var.cluster_create_security_group
  cluster_security_group_id            = var.cluster_security_group_id
  worker_additional_security_group_ids = var.worker_additional_security_group_ids

  # Endpoint config
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  # secret encryption
  cluster_encryption_config = var.enable_secret_encryption ? [
    {
      provider_key_arn = local.etcd_kms
      resources        = ["secrets"]
    }
  ] : []

  # IRSA
  enable_irsa = true

  # Managed Node Groups
  manage_worker_iam_resources  = var.manage_worker_iam_resources
  node_groups_defaults         = local.node_groups_defaults
  node_groups                  = var.node_groups
  worker_create_security_group = var.node_create_security_group
  worker_security_group_id     = var.node_security_group_id

  # Aws auth & kubeconfig
  manage_aws_auth  = false
  write_kubeconfig = false

  # Tagging
  tags = var.tags
}

################################################################################
# KMS for encrypting secrets
################################################################################

locals {
  etcd_kms = var.kms_etcd != null || ! var.enable_secret_encryption ? var.kms_etcd : aws_kms_key.this[0].arn
}

resource "aws_kms_key" "this" {
  count = var.kms_etcd != null || ! var.enable_secret_encryption ? 0 : 1

  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

locals {
  node_groups_defaults = merge({

    # Force to true to create a launch template to add worker security group to nodes
    create_launch_template = "true"

    ami_type  = var.node_group_ami_type
    disk_size = var.node_group_disk_size
    },
    var.node_group_iam_role_arn == null ? {} : { iam_role_arn = var.node_group_iam_role_arn },
    var.node_group_ami_id == null ? {} : { ami_id = var.node_group_ami_id },
  var.node_group_ami_type == null ? {} : { ami_type = var.node_group_ami_type })
}
