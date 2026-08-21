variable "aws_region" {
  description = "AWS region for state backend resources."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier (e.g. us-east-1)."
  }
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state."
  type        = string
  default     = "transactedge-terraform-state"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid S3 bucket name (3-63 chars, lowercase)."
  }
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking."
  type        = string
  default     = "transactedge-terraform-locks"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{3,255}$", var.lock_table_name))
    error_message = "lock_table_name must be 3-255 characters of letters, numbers, underscore, dot, or hyphen."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Days to retain noncurrent state object versions for rollback before expiration."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 30 && var.noncurrent_version_expiration_days <= 3650
    error_message = "noncurrent_version_expiration_days must be between 30 and 3650."
  }
}
