output "log_group_name" {
  description = "CloudWatch log group collecting EKS control plane logs"
  value       = try(aws_cloudwatch_log_group.eks[0].name, null)
}

output "sns_topic_arn" {
  description = "SNS topic used for monitoring alerts"
  value       = aws_sns_topic.alerts.arn
}

output "alarm_name" {
  description = "Name of the CloudWatch alarm for EKS errors"
  value       = try(aws_cloudwatch_metric_alarm.eks_errors[0].alarm_name, null)
}

output "prometheus_workspace_id" {
  description = "Amazon Managed Prometheus workspace ID"
  value       = try(aws_prometheus_workspace.this[0].id, null)
}

output "dashboard_name" {
  description = "CloudWatch dashboard providing an overview of cluster health"
  value       = aws_cloudwatch_dashboard.eks_overview.dashboard_name
}
