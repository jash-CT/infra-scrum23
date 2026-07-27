locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "msk"
  })

  cluster_name = "${var.name_prefix}-msk"
}

resource "aws_kms_key" "msk" {
  description             = "KMS key for MSK encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-msk-key"
  })
}

resource "aws_kms_alias" "msk" {
  name          = "alias/${var.name_prefix}-msk"
  target_key_id = aws_kms_key.msk.key_id
}

resource "aws_security_group" "msk" {
  name_prefix = "${var.name_prefix}-msk-"
  description = "Security group for MSK brokers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Kafka TLS from application security groups"
    from_port       = 9094
    to_port         = 9094
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  ingress {
    description     = "Kafka IAM from application security groups"
    from_port       = 9098
    to_port         = 9098
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  ingress {
    description     = "ZooKeeper from application security groups"
    from_port       = 2181
    to_port         = 2181
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
    Name = "${var.name_prefix}-msk-sg"
  })
}

resource "aws_msk_configuration" "main" {
  name              = "${var.name_prefix}-msk-config"
  kafka_versions    = [var.kafka_version]
  server_properties = <<-PROPERTIES
    auto.create.topics.enable=false
    default.replication.factor=3
    min.insync.replicas=2
    num.partitions=6
    log.retention.hours=168
    compression.type=lz4
  PROPERTIES

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_msk_cluster" "main" {
  cluster_name           = local.cluster_name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.subnet_ids
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.broker_volume_size
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn

    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
      s3 {
        enabled = false
      }
      firehose {
        enabled = false
      }
    }
  }

  enhanced_monitoring = "PER_TOPIC_PER_PARTITION"

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${local.cluster_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.msk.arn

  tags = local.common_tags
}
