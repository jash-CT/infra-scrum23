output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform remote state bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "lock_table_arn" {
  description = "ARN of the Terraform state lock table."
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "state_kms_key_arn" {
  description = "CMK ARN encrypting Terraform state objects."
  value       = aws_kms_key.terraform_state.arn
}

output "backend_config" {
  description = "Canonical S3 backend settings for environment stacks."
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    encrypt        = true
  }
}
