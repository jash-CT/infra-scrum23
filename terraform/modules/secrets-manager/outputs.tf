output "application_secret_arns" {
  description = "Map of application names to secret ARNs."
  value       = { for k, v in aws_secretsmanager_secret.application : k => v.arn }
}

output "application_secret_names" {
  description = "Map of application names to secret names."
  value       = { for k, v in aws_secretsmanager_secret.application : k => v.name }
}

output "all_secret_arns" {
  description = "List of all secret ARNs managed by this module."
  value       = concat(
    [for v in aws_secretsmanager_secret.application : v.arn],
    [aws_secretsmanager_secret.shared.arn]
  )
}

output "shared_secret_arn" {
  description = "ARN of the shared observability secret."
  value       = aws_secretsmanager_secret.shared.arn
}
