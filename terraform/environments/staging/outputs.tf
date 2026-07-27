output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "redis_endpoint" {
  value = module.elasticache.primary_endpoint_address
}

output "msk_cluster_arn" {
  value = module.msk.cluster_arn
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  value = module.cloudfront.distribution_domain_name
}

output "service_role_arns" {
  value = module.iam.service_role_arns
}
