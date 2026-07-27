output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "Connection endpoint for the RDS instance."
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "Port of the RDS instance."
  value       = aws_db_instance.main.port
}

output "db_security_group_id" {
  description = "Security group ID for RDS."
  value       = aws_security_group.rds.id
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing DB credentials."
  value       = aws_secretsmanager_secret.db_credentials.name
}
