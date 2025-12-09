locals {
  tags = merge(
    {
      Environment = var.environment
      Component   = "central-monitoring"
    },
    var.tags
  )
}

data "aws_region" "current" {}

resource "random_id" "suffix" {
  byte_length = 4
}

# ==================== IAM: Grafana workspace ====================
resource "aws_iam_role" "grafana" {
  name        = "grafana-${var.environment}-workspace-role"
  description = "IAM role for Grafana workspace and service access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy" "grafana_prometheus" {
  name = "grafana-prometheus-policy-${random_id.suffix.hex}"
  role = aws_iam_role.grafana.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:DescribeWorkspace",
          "aps:DescribeLoggingConfiguration",
          "aps:ListWorkspaces",
          "aps:GetSeries",
          "aps:QueryMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==================== Grafana Admin Secrets ====================
resource "aws_secretsmanager_secret" "grafana_admin" {
  name        = "central-grafana-${var.environment}"
  tags        = local.tags
  description = "Credentials for the central Grafana admin user"
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = aws_secretsmanager_secret.grafana_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = var.grafana_admin_password
  })
}

# ==================== SSM: Source catalog  ====================
resource "aws_ssm_parameter" "source_catalog" {
  name = "/central-monitoring/${var.environment}/sources"
  type = "String"
  value = jsonencode({
    aws_cloudwatch_log_group = var.aws_cloudwatch_log_group
    prometheus_retention     = var.prometheus_retention
  })
  tags        = local.tags
  description = "JSON catalog of monitoring data sources for the ${var.environment} environment"
}

# ==================== Prometheus workspace ====================
resource "aws_prometheus_workspace" "central" {
  alias = substr(replace("${random_id.suffix.hex}", "_", "-"), 0, 100)
  tags  = local.tags
}

# ==================== Grafana workspace ====================
resource "aws_grafana_workspace" "central" {
  name                      = "${random_id.suffix.hex}"
  account_access_type       = "CURRENT_ACCOUNT"
  authentication_providers  = ["SAML"]
  data_sources              = ["CLOUDWATCH", "PROMETHEUS", "XRAY"]
  notification_destinations = ["SNS"]
  permission_type           = "SERVICE_MANAGED"
  role_arn                  = aws_iam_role.grafana.arn
  tags                      = local.tags
}

# ==================== OpenSearch workspace ====================
resource "aws_opensearch_domain" "logs" {
  count       = var.opensearch_enabled ? 1 : 0
  domain_name = substr(replace("logs-${var.environment}-${random_id.suffix.hex}", "_", "-"), 0, 28)
  engine_version = "OpenSearch_2.13"
  auto_tune_options {
    desired_state = "DISABLED"
  }
  cluster_config {
    instance_type          = "t3.small.search"
    instance_count         = 2
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 2
    }
  }
  ebs_options {
    ebs_enabled = true
    volume_size = 50
    volume_type = "gp3"
  }
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "grafana-admin"
      master_user_password = var.grafana_admin_password
    }
  }
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }
  node_to_node_encryption {
    enabled = true
  }
  encrypt_at_rest {
    enabled = true
  }
  tags = local.tags
}

# ==================== Alerting (SNS) ====================
resource "aws_sns_topic" "central_alerts" {
  name = "central-monitoring-${var.environment}"
  display_name = "Central Monitoring Alerts - ${var.environment}"
  tags = local.tags
}

# ==================== CloudWatch Events ====================
resource "aws_cloudwatch_event_rule" "health" {
  name        = "central-monitoring-${var.environment}-health"
  description = "Capture health events across AWS accounts"
  event_pattern = jsonencode({
    "source" : ["aws.health"]
  })
  tags = local.tags
}

resource "aws_cloudwatch_event_target" "health_to_sns" {
  rule      = aws_cloudwatch_event_rule.health.name
  target_id = "sns"
  arn       = aws_sns_topic.central_alerts.arn
}

# ==================== CloudWatch Dashboards ====================
resource "aws_cloudwatch_dashboard" "central" {
  dashboard_name = "central-monitoring-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/Prometheus", "RuleEvaluations", { "stat" : "Sum" }]
          ],
          "title" : "Prometheus Rule Evaluations",
          "stat" : "Sum",
          "region" : data.aws_region.current.id, 
          "period" : 300,
          "yAxis" : {
            "left" : {
              "min" : 0
            }
          }
        }
      }
    ]
  })
}
