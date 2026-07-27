variable "name_prefix" {
  description = "Prefix applied to all EKS resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS worker nodes."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "EC2 instance types for managed node groups."
  type        = list(string)
  default     = ["m6i.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 10
}

variable "node_disk_size" {
  description = "Root volume size in GB for worker nodes."
  type        = number
  default     = 100
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API endpoint is publicly accessible."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to EKS resources."
  type        = map(string)
  default     = {}
}
