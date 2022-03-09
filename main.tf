################################################################################
# EKS Module
################################################################################

module "this" {
  source = "git@github.com:padok-team/terraform-aws-eks-community.git?ref=fix/prefix_separator_launch_templates"

  create           = true
  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  prefix_separator = var.prefix_separator

  create_iam_role          = false
  iam_role_arn             = var.iam_role_arn
  iam_role_use_name_prefix = false

  # Control plane logs
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # Network config
  vpc_id                               = var.vpc_id
  subnet_ids                           = var.subnet_ids
  cluster_service_ipv4_cidr            = var.service_ipv4_cidr
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Security groups
  create_cluster_security_group = var.create_cluster_security_group
  cluster_security_group_id     = var.cluster_security_group_id

  # Endpoint config
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  # secret encryption
  cluster_encryption_config = var.enable_secrets_encryption ? [
    {
      provider_key_arn = local.etcd_kms
      resources        = ["secrets"]
    }
  ] : []

  # IRSA
  enable_irsa = true

  # Managed Node Groups
  eks_managed_node_group_defaults = local.node_groups_defaults
  eks_managed_node_groups         = var.node_groups
  create_node_security_group      = var.node_create_security_group
  node_security_group_id          = var.node_security_group_id

  # Tagging
  tags = var.tags
}

################################################################################
# KMS for encrypting secrets
################################################################################

locals {
  etcd_kms = var.kms_etcd != null || !var.enable_secrets_encryption ? var.kms_etcd : aws_kms_key.this[0].arn
}

resource "aws_kms_key" "this" {
  count = var.kms_etcd != null || !var.enable_secrets_encryption ? 0 : 1

  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

locals {
  node_groups_defaults = merge({

    # Force to true to create a launch template to add worker security group to nodes
    create_launch_template = true
    },
    var.node_group_iam_role_arn == null ? {} : { iam_role_arn = var.node_group_iam_role_arn },
    var.node_group_ami_id == null ? {} : { ami_id = var.node_group_ami_id },
    var.node_group_ami_type == null ? {} : { ami_type = var.node_group_ami_type },
    var.custom_node_group_defaults
  )
}
