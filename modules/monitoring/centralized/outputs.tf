output "grafana_url" {
  description = "URL to access the managed Grafana workspace"
  value       = aws_grafana_workspace.central.endpoint
}

output "prometheus_url" {
  description = "Ingestion endpoint for Amazon Managed Prometheus"
  value       = aws_prometheus_workspace.central.prometheus_endpoint
}

output "kibana_url" {
  description = "Dashboard endpoint for OpenSearch (Kibana-compatible)"
  value       = aws_opensearch_domain.logs.dashboard_endpoint
}

output "opensearch_domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.logs.arn
}

output "sns_topic_arn" {
  description = "SNS topic receiving global health alerts"
  value       = aws_sns_topic.central_alerts.arn
}

output "configuration_parameter" {
  description = "SSM parameter storing source catalog"
  value       = aws_ssm_parameter.source_catalog.name
}
