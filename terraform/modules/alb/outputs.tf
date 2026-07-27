output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the ALB."
  value       = aws_lb.main.zone_id
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB."
  value       = aws_security_group.alb.id
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener."
  value       = aws_lb_listener.https.arn
}

output "alb_logs_bucket_id" {
  description = "S3 bucket ID for ALB access logs."
  value       = aws_s3_bucket.alb_logs.id
}
