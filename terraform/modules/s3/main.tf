locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3"
  })

  buckets = {
    audit_logs = {
      name_suffix = "audit-logs"
      purpose     = "PCI DSS audit log storage"
    }
    settlement_files = {
      name_suffix = "settlement-files"
      purpose     = "Payment settlement file storage"
    }
    merchant_documents = {
      name_suffix = "merchant-documents"
      purpose     = "Merchant onboarding document storage"
    }
  }
}

resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-s3-key"
  })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_s3_bucket" "main" {
  for_each = local.buckets

  bucket = "${var.name_prefix}-${each.value.name_suffix}"

  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-${each.value.name_suffix}"
    Purpose = each.value.purpose
  })
}

resource "aws_s3_bucket_versioning" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket_logging" "main" {
  for_each = var.enable_logging ? aws_s3_bucket.main : {}

  bucket = each.value.id

  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "${each.key}/"
}

resource "aws_s3_bucket" "access_logs" {
  count = var.enable_logging ? 1 : 0

  bucket = "${var.name_prefix}-s3-access-logs"

  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-s3-access-logs"
    Purpose = "S3 access log aggregation"
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}
