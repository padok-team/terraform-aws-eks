#### ---- ---- ---- GLOBAL ---- ---- ---- ####
variable "env" {
  type        = string
  description = "Environment name"
}
variable "region" {
  type        = string
  description = "AWS region name"
}

#### ---- ---- ---- EKS ---- ---- ---- ####
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}
variable "cluster_version" {
  type        = string
  description = "EKS version"
}

#### logging
variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

#### endpoints
variable "cluster_endpoint_public_access" {
  type        = bool
  default     = false
  description = "Enable API Server public endpoint"
}
variable "cluster_endpoint_private_access" {
  type        = bool
  default     = true
  description = "Enable API Server private endpoint"
}
variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["192.168.0.1/32"] # fake value because we don't want everyone access our endpoint when public is enabled
}

#### network
variable "vpc_id" {
  type        = string
  description = "VPC ID for EKS"
}
variable "subnets" {
  description = "A list of subnets to place the EKS cluster and workers within."
  type        = list(string)
  default     = []
}
variable "service_ipv4_cidr" {
  type        = string
  description = "service ipv4 cidr for the kubernetes cluster"
  default     = null
}

#### secret encryption
variable "kms_etcd" {
  type        = string
  description = "KMS key ARN for etcd encryption"
  default     = null
}

#### node groups
variable "node_group_ami_type" {
  type        = string
  default     = "AL2_x86_64"
  description = "AMI type for EKS Nodes"
}
variable "node_group_disk_size" {
  type        = number
  default     = 20
  description = "EBS disk size for node group"
}
variable "node_groups" {
  description = "Map of map of node groups to create. See `node_groups` module's documentation for more details"
  type        = any
  default     = {}
}

# tags rulez the world
variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default     = {}
}
