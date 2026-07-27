variable "name_prefix" {
  description = "Prefix applied to all IAM resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider."
  type        = string
}

variable "msk_cluster_arn" {
  description = "ARN of the MSK cluster for Kafka IAM policies."
  type        = string
}

variable "s3_bucket_arns" {
  description = "ARNs of S3 buckets for application access policies."
  type        = list(string)
}

variable "secrets_manager_arns" {
  description = "ARNs of Secrets Manager secrets for application access."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
