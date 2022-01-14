#### ---- ---- ---- GLOBAL ---- ---- ---- ####
variable "env" {
  description = "Environment name"
  type        = string
}
variable "region" {
  description = "AWS region name"
  type        = string
}

#### ---- ---- ---- EKS ---- ---- ---- ####
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}
variable "cluster_version" {
  description = "EKS version"
  type        = string
}

variable "manage_cluster_iam_resources" {
  description = "Whether to let the module manage cluster IAM resources. If set to false, cluster_iam_role_name must be specified."
  type        = bool
  default     = true
}

variable "cluster_iam_role_name" {
  description = "IAM role name for the cluster. If manage_cluster_iam_resources is set to false, set this to reuse an existing IAM role. If manage_cluster_iam_resources is set to true, set this to force the created role name."
  type        = string
  default     = ""
}

#### Logging
variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

#### Endpoints
variable "cluster_endpoint_public_access" {
  description = "Enable API Server public endpoint"
  type        = bool
  default     = false
}
variable "cluster_endpoint_private_access" {
  description = "Enable API Server private endpoint"
  type        = bool
  default     = true
}
variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["192.168.0.1/32"] # fake value because we don't want everyone access our endpoint when public is enabled
}

#### Network
variable "vpc_id" {
  description = "VPC ID for EKS"
  type        = string
}
variable "subnets" {
  description = "A list of subnets to place the EKS cluster and workers within."
  type        = list(string)
  default     = []
}
variable "service_ipv4_cidr" {
  description = "service ipv4 cidr for the kubernetes cluster"
  type        = string
  default     = null
}

#### Security groups
variable "cluster_create_security_group" {
  description = "Indicate wether a new security group must be created or not"
  type        = bool
  default     = true
}

variable "cluster_security_group_id" {
  description = "If provided, the EKS cluster will be attached to this security group. If not given, a security group will be created with necessary ingress/egress to work with the workers"
  type        = string
  default     = ""
}

variable "worker_additional_security_group_ids" {
  description = "A list of additional security group ids to attach to worker instances	"
  type        = list(string)
  default     = []
}
#### Secret encryption
variable "kms_etcd" {
  description = "KMS key ARN for etcd encryption"
  type        = string
  default     = null
}

#### Node groups
variable "node_group_ami_type" {
  description = "AMI type for EKS Nodes"
  type        = string
  default     = null
}

variable "node_group_ami_id" {
  description = "ID of the AMI to use on the EKS Nodes"
  type        = string
  default     = null
}
variable "node_group_disk_size" {
  description = "EBS disk size for node group"
  type        = number
  default     = 20
}

variable "node_group_iam_role_arn" {
  description = "IAM role ARN for workers"
  type        = string
  default     = null
}
variable "node_groups" {
  description = "Map of map of node groups to create. See `node_groups` module's documentation for more details"
  type        = any
  default     = {}
}

variable "manage_worker_iam_resources" {
  description = "Whether to let the module manage worker IAM resources. If set to false, iam_role_arn must be specified for nodes."
  type        = bool
  default     = true
}

#### Tags rulez the world
variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default     = {}
}
