output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "API server endpoint for the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for cluster TLS"
  value       = try(aws_eks_cluster.this.certificate_authority[0].data, null)
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group attached to the EKS control plane"
  value       = aws_security_group.cluster.id
}

output "node_group_id" {
  description = "ID of the managed node group"
  value       = aws_eks_node_group.this.id
}

output "node_group_name" {
  description = "Name of the managed node group"
  value       = try(aws_eks_node_group.this.node_group_name, null)
}

output "node_role_arn" {
  description = "ARN of the IAM role assumed by the node group"
  value       = aws_iam_role.node_group.arn
}
