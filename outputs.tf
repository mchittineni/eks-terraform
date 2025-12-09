### 🌐 Networking Outputs

output "aws_vpc_id" {
  description = "The unique identifier (ID) of the AWS Virtual Private Cloud (VPC)."
  value       = module.aws_networking.vpc_id
}

### ☁️ AWS Compute (EKS) Outputs

output "aws_eks_cluster_name" {
  description = "The name of the AWS EKS Kubernetes cluster."
  value       = module.aws_compute.cluster_name
}

output "aws_eks_cluster_endpoint" {
  description = "The API endpoint URL for the AWS EKS cluster control plane."
  value       = module.aws_compute.cluster_endpoint
  sensitive   = true
}

output "kubectl_config_commands" {
  description = "Command required to configure 'kubectl' to connect to the AWS EKS cluster."
  value = merge(
    {
      aws = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.aws_compute.cluster_name}"
    },
  )
}

### 💾 AWS Data & Storage Outputs

output "aws_rds_endpoint" {
  description = "The connection endpoint (DNS name) for the AWS RDS database instance."
  value       = module.aws_database.db_endpoint
  sensitive   = true
}

output "database_connection_info" {
  description = "Detailed database connection parameters (endpoint, port, and database name)."
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

output "aws_s3_bucket_name" {
  description = "The name of the S3 bucket provisioned for database backups or general storage."
  value       = module.aws_database.s3_bucket_name
}

### 📈 Monitoring Outputs

output "aws_cloudwatch_log_group" {
  description = "The name of the primary CloudWatch log group used for centralized logging."
  value       = module.aws_monitoring.log_group_name
}

output "grafana_url" {
  description = "The external URL to access the Grafana visualization dashboard."
  value       = module.centralized_monitoring.grafana_url
}

output "prometheus_url" {
  description = "The external URL to access the Prometheus time-series database."
  value       = module.centralized_monitoring.prometheus_url
}

output "kibana_url" {
  description = "The external URL to access the Kibana interface for log analysis."
  value       = module.centralized_monitoring.kibana_url
}

### 📝 Deployment Summary Output

output "deployment_summary" {
  description = "A comprehensive map summarizing the deployed infrastructure details."
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
