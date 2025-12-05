# ==================== AWS Outputs ====================

output "aws_vpc_id" {
  description = "ID of the AWS VPC"
  value       = module.aws_networking.vpc_id
}

output "aws_eks_cluster_endpoint" {
  description = "Endpoint for AWS EKS cluster"
  value       = module.aws_compute.cluster_endpoint
  sensitive   = true
}

output "aws_eks_cluster_name" {
  description = "Name of the AWS EKS cluster"
  value       = module.aws_compute.cluster_name
}

output "aws_rds_endpoint" {
  description = "Connection endpoint for AWS RDS"
  value       = module.aws_database.db_endpoint
  sensitive   = true
}

output "aws_s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.aws_database.s3_bucket_name
}

output "aws_cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.aws_monitoring.log_group_name
}

# ==================== Monitoring Outputs ====================

output "grafana_url" {
  description = "URL to access Grafana dashboard"
  value       = module.centralized_monitoring.grafana_url
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = module.centralized_monitoring.prometheus_url
}

output "kibana_url" {
  description = "URL to access Kibana"
  value       = module.centralized_monitoring.kibana_url
}

# ==================== Summary Output ====================

output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment = var.environment
    project     = var.project_name
    aws = {
      region       = var.aws_region
      cluster_name = module.aws_compute.cluster_name
      vpc_id       = module.aws_networking.vpc_id
    }
    monitoring = {
      enabled     = var.enable_monitoring
      grafana_url = module.centralized_monitoring.grafana_url
    }
  }
}

# ==================== Kubernetes Config Commands ====================

output "kubectl_config_commands" {
  description = "Commands to configure kubectl for each cluster"
  value = merge(
    {
      aws = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.aws_compute.cluster_name}"
    },
  )
}

# ==================== Database Connection Strings ====================

output "database_connection_info" {
  description = "Database connection information (sensitive)"
  value = merge(
    {
      aws_rds = {
        endpoint = module.aws_database.db_endpoint
        port     = 5432
        database = var.aws_db_name
      }
    },
  )
  sensitive = true
}