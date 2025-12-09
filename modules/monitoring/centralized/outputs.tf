output "grafana_url" {
  description = "URL to access the managed Grafana workspace (if created)."
  value       = try(aws_grafana_workspace.central.endpoint, null)
}

output "grafana_workspace_id" {
  description = "ID of the managed Grafana workspace (if created)."
  value       = try(aws_grafana_workspace.central.id, null)
}

output "prometheus_url" {
  description = "Ingestion endpoint for Amazon Managed Prometheus (if created)."
  value       = try(aws_prometheus_workspace.central.prometheus_endpoint, null)
}

output "prometheus_workspace_id" {
  description = "ID of the Prometheus workspace (if created)."
  value       = try(aws_prometheus_workspace.central.id, null)
}

output "kibana_url" {
  description = "Dashboard endpoint for OpenSearch (Kibana-compatible) if OpenSearch is enabled."
  value       = try(aws_opensearch_domain.logs[0].dashboard_endpoint, null)
}

output "opensearch_domain_arn" {
  description = "ARN of the OpenSearch domain (if created)."
  value       = try(aws_opensearch_domain.logs[0].arn, null)
}

output "sns_topic_arn" {
  description = "SNS topic ARN receiving global health alerts (if created)."
  value       = try(aws_sns_topic.central_alerts.arn, null)
}

output "sns_topic_name" {
  description = "SNS topic name used for central alerts."
  value       = try(aws_sns_topic.central_alerts.name, null)
}

output "configuration_parameter_name" {
  description = "SSM parameter name storing the source catalog (if created)."
  value       = try(aws_ssm_parameter.source_catalog.name, null)
}

output "configuration_parameter_arn" {
  description = "SSM parameter ARN for the source catalog (if created)."
  value       = try(aws_ssm_parameter.source_catalog.arn, null)
}
