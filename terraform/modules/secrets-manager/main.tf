locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "secrets-manager"
  })

  application_secrets = {
    "payments-api" = {
      description = "Application secrets for payments-api"
      keys        = ["api_key_salt", "jwt_signing_key", "webhook_signing_secret"]
    }
    "fraud-engine" = {
      description = "Application secrets for fraud-engine"
      keys        = ["model_api_key", "rules_engine_token"]
    }
    "merchant-portal" = {
      description = "Application secrets for merchant-portal"
      keys        = ["session_secret", "oauth_client_secret", "nextauth_secret"]
    }
  }
}

resource "aws_secretsmanager_secret" "application" {
  for_each = local.application_secrets

  name        = "${var.name_prefix}/${each.key}"
  description = each.value.description
  kms_key_id  = var.kms_key_arn

  recovery_window_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.common_tags, {
    Application = each.key
  })
}

resource "aws_secretsmanager_secret_version" "application" {
  for_each = local.application_secrets

  secret_id = aws_secretsmanager_secret.application[each.key].id

  secret_string = jsonencode({
    for key in each.value.keys : key => "CHANGE_ME_ON_INITIAL_DEPLOY"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "shared" {
  name        = "${var.name_prefix}/shared/datadog"
  description = "Shared observability credentials"
  kms_key_id  = var.kms_key_arn

  recovery_window_in_days = var.environment == "production" ? 30 : 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "shared" {
  secret_id = aws_secretsmanager_secret.shared.id

  secret_string = jsonencode({
    api_key = "CHANGE_ME_ON_INITIAL_DEPLOY"
    app_key = "CHANGE_ME_ON_INITIAL_DEPLOY"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
