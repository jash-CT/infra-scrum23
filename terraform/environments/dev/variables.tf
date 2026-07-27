variable "aws_region" {
  description = "AWS region for dev environment."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks."
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks."
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Database subnet CIDR blocks."
  type        = list(string)
  default     = ["10.10.201.0/24", "10.10.202.0/24"]
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "EKS node instance types."
  type        = list(string)
  default     = ["m6i.large"]
}

variable "node_desired_size" {
  description = "Desired EKS node count."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum EKS node count."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum EKS node count."
  type        = number
  default     = 4
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access EKS API."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.medium"
}

variable "elasticache_node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.medium"
}

variable "msk_broker_instance_type" {
  description = "MSK broker instance type."
  type        = string
  default     = "kafka.t3.small"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for ALB."
  type        = string
}

variable "cloudfront_aliases" {
  description = "CloudFront alternate domain names."
  type        = list(string)
  default     = []
}

variable "cloudfront_acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (us-east-1)."
  type        = string
  default     = ""
}
