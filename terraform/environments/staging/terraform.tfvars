aws_region = "us-east-1"

vpc_cidr              = "10.20.0.0/16"
availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
public_subnet_cidrs   = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]
database_subnet_cidrs = ["10.20.201.0/24", "10.20.202.0/24", "10.20.203.0/24"]

kubernetes_version  = "1.29"
node_instance_types = ["m6i.large"]
node_desired_size   = 3
node_min_size       = 2
node_max_size       = 8

rds_instance_class       = "db.r6g.large"
elasticache_node_type    = "cache.r6g.large"
msk_broker_instance_type = "kafka.m5.large"

acm_certificate_arn            = "arn:aws:acm:us-east-1:000000000000:certificate/00000000-0000-0000-0000-000000000010"
cloudfront_aliases             = ["staging.transactedge.com"]
cloudfront_acm_certificate_arn = "arn:aws:acm:us-east-1:000000000000:certificate/00000000-0000-0000-0000-000000000011"
