variable "name_prefix" {
  description = "Prefix applied to all VPC resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones for subnet placement."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to provision NAT gateways for private subnet egress."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway instead of one per AZ (cost optimization for non-production)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to all VPC resources."
  type        = map(string)
  default     = {}
}
