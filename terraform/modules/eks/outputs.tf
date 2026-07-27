output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint URL for the EKS control plane."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to EKS worker nodes."
  value       = aws_security_group.nodes.id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "node_group_role_arn" {
  description = "IAM role ARN for the managed node group."
  value       = aws_iam_role.node_group.arn
}
