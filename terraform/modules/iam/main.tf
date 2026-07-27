locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "iam"
  })

  oidc_provider_host = replace(var.oidc_provider_url, "https://", "")

  services = {
    payments-api = {
      namespace            = "payments"
      service_account_name = "payments-api"
    }
    fraud-engine = {
      namespace            = "fraud"
      service_account_name = "fraud-engine"
    }
    merchant-portal = {
      namespace            = "merchant"
      service_account_name = "merchant-portal"
    }
    external-secrets = {
      namespace            = "external-secrets"
      service_account_name = "external-secrets"
    }
  }
}

resource "aws_iam_role" "service" {
  for_each = local.services

  name = "${var.name_prefix}-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${local.oidc_provider_host}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
          "${local.oidc_provider_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Service = each.key
  })
}

resource "aws_iam_role_policy" "payments_api" {
  name = "${var.name_prefix}-payments-api-policy"
  role = aws_iam_role.service["payments-api"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = var.secrets_manager_arns
      },
      {
        Sid    = "MSKAccess"
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData",
        ]
        Resource = [
          var.msk_cluster_arn,
          "${var.msk_cluster_arn}/*",
        ]
      },
      {
        Sid    = "S3SettlementAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Resource = flatten([
          for arn in var.s3_bucket_arns : [arn, "${arn}/*"]
        ])
      },
    ]
  })
}

resource "aws_iam_role_policy" "fraud_engine" {
  name = "${var.name_prefix}-fraud-engine-policy"
  role = aws_iam_role.service["fraud-engine"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = var.secrets_manager_arns
      },
      {
        Sid    = "MSKConsumerAccess"
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:ReadData",
        ]
        Resource = [
          var.msk_cluster_arn,
          "${var.msk_cluster_arn}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "merchant_portal" {
  name = "${var.name_prefix}-merchant-portal-policy"
  role = aws_iam_role.service["merchant-portal"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = var.secrets_manager_arns
      },
      {
        Sid    = "S3MerchantDocuments"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Resource = flatten([
          for arn in var.s3_bucket_arns : [arn, "${arn}/*"]
        ])
      },
    ]
  })
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "${var.name_prefix}-external-secrets-policy"
  role = aws_iam_role.service["external-secrets"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerSync"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "${var.name_prefix}-github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:transactedge/payments-api:*",
            "repo:transactedge/fraud-engine:*",
            "repo:transactedge/merchant-portal:*",
            "repo:transactedge/infra:*",
          ]
        }
      }
    }]
  })

  tags = local.common_tags
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "${var.name_prefix}-github-actions-deploy-policy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
        ]
        Resource = "*"
      },
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
        ]
        Resource = "*"
      },
    ]
  })
}
