output "replication_group_id" {
  description = "ElastiCache replication group ID."
  value       = aws_elasticache_replication_group.main.id
}

output "primary_endpoint_address" {
  description = "Primary endpoint address for Redis."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address for Redis."
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_security_group_id" {
  description = "Security group ID for Redis."
  value       = aws_security_group.redis.id
}

output "redis_auth_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis auth token."
  value       = aws_secretsmanager_secret.redis_auth.arn
}
