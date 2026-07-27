variable "name_prefix" {
  description = "Prefix applied to all RDS resource names."
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

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group."
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security group IDs permitted to connect to RDS."
  type        = list(string)
}

variable "engine" {
  description = "Database engine."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version."
  type        = string
  default     = "15.5"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.r6g.large"
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Maximum autoscaling storage in GB."
  type        = number
  default     = 500
}

variable "database_name" {
  description = "Name of the default database."
  type        = string
  default     = "transactedge"
}

variable "master_username" {
  description = "Master username for the database."
  type        = string
  default     = "transactedge_admin"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 14
}

variable "deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to RDS resources."
  type        = map(string)
  default     = {}
}
