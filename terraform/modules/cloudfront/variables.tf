variable "name_prefix" {
  description = "Prefix applied to all CloudFront resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "origin_domain_name" {
  description = "Origin domain name (ALB DNS name)."
  type        = string
}

variable "aliases" {
  description = "Alternate domain names (CNAMEs) for the distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1)."
  type        = string
}

variable "enable_waf" {
  description = "Associate AWS WAF with CloudFront."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to CloudFront resources."
  type        = map(string)
  default     = {}
}
