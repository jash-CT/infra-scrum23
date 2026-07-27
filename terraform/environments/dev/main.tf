terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "transactedge-terraform-state"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "transactedge-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "transactedge"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "transactedge"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "te-dev"
  common_tags = {
    Project     = "transactedge"
    Environment = "dev"
    CostCenter  = "platform-engineering"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix            = local.name_prefix
  environment            = "dev"
  vpc_cidr               = var.vpc_cidr
  availability_zones     = var.availability_zones
  private_subnet_cidrs   = var.private_subnet_cidrs
  public_subnet_cidrs    = var.public_subnet_cidrs
  database_subnet_cidrs  = var.database_subnet_cidrs
  enable_nat_gateway     = true
  single_nat_gateway     = true
  tags                   = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  name_prefix                          = local.name_prefix
  environment                          = "dev"
  vpc_id                               = module.vpc.vpc_id
  private_subnet_ids                   = module.vpc.private_subnet_ids
  kubernetes_version                   = var.kubernetes_version
  node_instance_types                  = var.node_instance_types
  node_desired_size                    = var.node_desired_size
  node_min_size                        = var.node_min_size
  node_max_size                        = var.node_max_size
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  tags                                 = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix                = local.name_prefix
  environment                = "dev"
  vpc_id                     = module.vpc.vpc_id
  db_subnet_group_name       = module.vpc.db_subnet_group_name
  allowed_security_group_ids = [module.eks.node_security_group_id]
  instance_class             = var.rds_instance_class
  multi_az                   = false
  backup_retention_period    = 7
  deletion_protection        = false
  tags                       = local.common_tags
}

module "elasticache" {
  source = "../../modules/elasticache"

  name_prefix                = local.name_prefix
  environment                = "dev"
  vpc_id                     = module.vpc.vpc_id
  subnet_group_name          = module.vpc.elasticache_subnet_group_name
  allowed_security_group_ids = [module.eks.node_security_group_id]
  node_type                  = var.elasticache_node_type
  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false
  tags                       = local.common_tags
}

module "msk" {
  source = "../../modules/msk"

  name_prefix                = local.name_prefix
  environment                = "dev"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]
  number_of_broker_nodes     = 2
  broker_instance_type       = var.msk_broker_instance_type
  broker_volume_size         = 100
  tags                       = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  name_prefix = local.name_prefix
  environment = "dev"
  tags        = local.common_tags
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for application secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secrets-key"
  })
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  name_prefix = local.name_prefix
  environment = "dev"
  kms_key_arn = aws_kms_key.secrets.arn
  tags        = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix          = local.name_prefix
  environment          = "dev"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  msk_cluster_arn      = module.msk.cluster_arn
  s3_bucket_arns       = values(module.s3.bucket_arns)
  secrets_manager_arns = module.secrets_manager.all_secret_arns
  tags                 = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix       = local.name_prefix
  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn   = var.acm_certificate_arn
  enable_waf        = false
  tags              = local.common_tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix         = local.name_prefix
  environment         = "dev"
  origin_domain_name  = module.alb.alb_dns_name
  aliases             = var.cloudfront_aliases
  acm_certificate_arn = var.cloudfront_acm_certificate_arn
  enable_waf          = false
  tags                = local.common_tags
}
