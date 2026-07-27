variable "name_prefix" {
  description = "Prefix applied to all MSK resource names."
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

variable "subnet_ids" {
  description = "Subnet IDs for MSK broker placement."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs permitted to connect to MSK."
  type        = list(string)
}

variable "kafka_version" {
  description = "Apache Kafka version."
  type        = string
  default     = "3.5.1"
}

variable "number_of_broker_nodes" {
  description = "Total number of broker nodes."
  type        = number
  default     = 3
}

variable "broker_instance_type" {
  description = "MSK broker instance type."
  type        = string
  default     = "kafka.m5.large"
}

variable "broker_volume_size" {
  description = "EBS volume size per broker in GB."
  type        = number
  default     = 500
}

variable "tags" {
  description = "Additional tags applied to MSK resources."
  type        = map(string)
  default     = {}
}
