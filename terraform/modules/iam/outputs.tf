output "service_role_arns" {
  description = "Map of service names to IAM role ARNs."
  value       = { for k, v in aws_iam_role.service : k => v.arn }
}

output "payments_api_role_arn" {
  description = "IAM role ARN for payments-api."
  value       = aws_iam_role.service["payments-api"].arn
}

output "fraud_engine_role_arn" {
  description = "IAM role ARN for fraud-engine."
  value       = aws_iam_role.service["fraud-engine"].arn
}

output "merchant_portal_role_arn" {
  description = "IAM role ARN for merchant-portal."
  value       = aws_iam_role.service["merchant-portal"].arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator."
  value       = aws_iam_role.service["external-secrets"].arn
}

output "github_actions_deploy_role_arn" {
  description = "IAM role ARN for GitHub Actions deployment."
  value       = aws_iam_role.github_actions_deploy.arn
}
