output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets."
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of database subnets."
  value       = aws_subnet.database[*].id
}

output "db_subnet_group_name" {
  description = "Name of the RDS subnet group."
  value       = aws_db_subnet_group.main.name
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group."
  value       = aws_elasticache_subnet_group.main.name
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways."
  value       = aws_nat_gateway.main[*].id
}
