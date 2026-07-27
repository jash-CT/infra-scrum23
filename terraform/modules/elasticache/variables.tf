variable "name_prefix" {
  description = "Prefix applied to all ElastiCache resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group placement."
  type        = string
}

variable "subnet_group_name" {
  description = "ElastiCache subnet group name."
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security group IDs permitted to connect to Redis."
  type        = list(string)
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.r6g.large"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group."
  type        = number
  default     = 2
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover for the replication group."
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ for the replication group."
  type        = bool
  default     = true
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "tags" {
  description = "Additional tags applied to ElastiCache resources."
  type        = map(string)
  default     = {}
}
