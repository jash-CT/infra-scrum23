variable "name_prefix" {
  description = "Prefix applied to all ALB resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ALB placement."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB placement."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_waf" {
  description = "Associate AWS WAF with the ALB."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to ALB resources."
  type        = map(string)
  default     = {}
}
