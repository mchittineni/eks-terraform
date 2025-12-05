locals {
  merged_tags = merge(
    {
      Environment = var.environment
      Component   = "monitoring"
    },
    var.tags
  )
}

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "eks" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30

  tags = local.merged_tags
}

resource "aws_sns_topic" "alerts" {
  name = "${var.cluster_name}-${var.environment}-alerts"

  tags = local.merged_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_log_metric_filter" "eks_errors" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name           = "${var.cluster_name}-error-count"
  log_group_name = aws_cloudwatch_log_group.eks[0].name
  pattern        = "\"ERROR\" || \"Warning\""

  metric_transformation {
    name          = "EKSControlPlaneErrors"
    namespace     = "Custom/EKS"
    value         = "1"
    default_value = 0
    dimensions    = { ClusterName = var.cluster_name }
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_errors" {
  count               = var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.cluster_name}-eks-errors"
  alarm_description   = "Alerts when control plane emits warnings or errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 10
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.eks_errors[0].metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.eks_errors[0].metric_transformation[0].namespace
  statistic           = "Sum"
  period              = 300

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  dimensions    = { ClusterName = var.cluster_name }

  tags = local.merged_tags
}

resource "aws_prometheus_workspace" "this" {
  count = var.enable_prometheus ? 1 : 0

  alias = substr(replace("${var.cluster_name}-${var.environment}", "_", "-"), 0, 100)
  tags  = local.merged_tags
}

resource "aws_cloudwatch_dashboard" "eks_overview" {
  dashboard_name = "${var.cluster_name}-${var.environment}-eks"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["Custom/EKS", "EKSControlPlaneErrors", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Sum"
          title  = "EKS Control Plane Errors"
        }
      }
    ]
  })
}
