output "bucket_ids" {
  description = "Map of bucket logical names to bucket IDs."
  value       = { for k, v in aws_s3_bucket.main : k => v.id }
}

output "bucket_arns" {
  description = "Map of bucket logical names to bucket ARNs."
  value       = { for k, v in aws_s3_bucket.main : k => v.arn }
}

output "audit_logs_bucket_arn" {
  description = "ARN of the audit logs bucket."
  value       = aws_s3_bucket.main["audit_logs"].arn
}

output "settlement_files_bucket_arn" {
  description = "ARN of the settlement files bucket."
  value       = aws_s3_bucket.main["settlement_files"].arn
}

output "merchant_documents_bucket_arn" {
  description = "ARN of the merchant documents bucket."
  value       = aws_s3_bucket.main["merchant_documents"].arn
}

output "s3_kms_key_arn" {
  description = "KMS key ARN used for S3 encryption."
  value       = aws_kms_key.s3.arn
}
