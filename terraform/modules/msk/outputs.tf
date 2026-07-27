output "cluster_arn" {
  description = "ARN of the MSK cluster."
  value       = aws_msk_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the MSK cluster."
  value       = aws_msk_cluster.main.cluster_name
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs for MSK brokers."
  value       = aws_msk_cluster.main.bootstrap_brokers_tls
  sensitive   = true
}

output "bootstrap_brokers_sasl_iam" {
  description = "SASL/IAM connection host:port pairs for MSK brokers."
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_iam
  sensitive   = true
}

output "msk_security_group_id" {
  description = "Security group ID for MSK."
  value       = aws_security_group.msk.id
}

output "msk_kms_key_arn" {
  description = "KMS key ARN used for MSK encryption."
  value       = aws_kms_key.msk.arn
}
