variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.30.101.0/24", "10.30.102.0/24", "10.30.103.0/24"]
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.30.201.0/24", "10.30.202.0/24", "10.30.203.0/24"]
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["m6i.xlarge"]
}

variable "node_desired_size" {
  type    = number
  default = 6
}

variable "node_min_size" {
  type    = number
  default = 3
}

variable "node_max_size" {
  type    = number
  default = 20
}

variable "rds_instance_class" {
  type    = string
  default = "db.r6g.xlarge"
}

variable "elasticache_node_type" {
  type    = string
  default = "cache.r6g.xlarge"
}

variable "msk_broker_instance_type" {
  type    = string
  default = "kafka.m5.xlarge"
}

variable "acm_certificate_arn" {
  type = string
}

variable "cloudfront_aliases" {
  type    = list(string)
  default = []
}

variable "cloudfront_acm_certificate_arn" {
  type = string
}
