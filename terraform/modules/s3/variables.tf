variable "name_prefix" {
  description = "Prefix applied to all S3 bucket names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on S3 buckets."
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable server access logging."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to S3 resources."
  type        = map(string)
  default     = {}
}
