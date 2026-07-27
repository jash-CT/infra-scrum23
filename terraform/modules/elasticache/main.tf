locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "elasticache"
  })

  replication_group_id = "${var.name_prefix}-redis"
}

resource "aws_kms_key" "elasticache" {
  description             = "KMS key for ElastiCache encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-elasticache-key"
  })
}

resource "aws_kms_alias" "elasticache" {
  name          = "alias/${var.name_prefix}-elasticache"
  target_key_id = aws_kms_key.elasticache.key_id
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.name_prefix}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from application security groups"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-redis-sg"
  })
}

resource "aws_elasticache_parameter_group" "main" {
  name_prefix = "${var.name_prefix}-redis7-"
  family      = "redis7"
  description = "Redis 7 parameter group for TransactEdge"

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = local.replication_group_id
  description          = "Redis cluster for ${var.name_prefix}"

  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  parameter_group_name = aws_elasticache_parameter_group.main.name
  subnet_group_name    = var.subnet_group_name
  security_group_ids   = [aws_security_group.redis.id]
  port                 = 6379

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.elasticache.arn
  transit_encryption_enabled = true
  auth_token                 = random_password.auth.result

  snapshot_retention_limit = 7
  snapshot_window          = "02:00-03:00"
  maintenance_window       = "sun:03:00-sun:04:00"

  apply_immediately = false

  tags = local.common_tags
}

resource "random_password" "auth" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name_prefix = "${var.name_prefix}-redis-auth-"
  description = "Redis auth token for ${local.replication_group_id}"

  kms_key_id = aws_kms_key.elasticache.arn

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = aws_secretsmanager_secret.redis_auth.id

  secret_string = jsonencode({
    auth_token = random_password.auth.result
    host       = aws_elasticache_replication_group.main.primary_endpoint_address
    port       = 6379
    tls        = true
  })
}
