aws_region = "us-east-1"

vpc_cidr              = "10.10.0.0/16"
availability_zones    = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
public_subnet_cidrs   = ["10.10.101.0/24", "10.10.102.0/24"]
database_subnet_cidrs = ["10.10.201.0/24", "10.10.202.0/24"]

kubernetes_version  = "1.29"
node_instance_types = ["m6i.large"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 4

rds_instance_class         = "db.t4g.medium"
elasticache_node_type      = "cache.t4g.medium"
msk_broker_instance_type   = "kafka.t3.small"

# Replace with actual ACM certificate ARN after provisioning
acm_certificate_arn = "arn:aws:acm:us-east-1:000000000000:certificate/00000000-0000-0000-0000-000000000000"

cloudfront_aliases             = ["dev.transactedge.com"]
cloudfront_acm_certificate_arn = "arn:aws:acm:us-east-1:000000000000:certificate/00000000-0000-0000-0000-000000000001"
