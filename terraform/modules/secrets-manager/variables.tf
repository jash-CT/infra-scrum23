variable "name_prefix" {
  description = "Prefix applied to all Secrets Manager resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for secret encryption."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to Secrets Manager resources."
  type        = map(string)
  default     = {}
}
