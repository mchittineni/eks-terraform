
variable "name_prefix" {
  description = "Optional name prefix applied to created resources (recommended short alphanumeric)."
  type        = string
  default     = "central"
}

variable "environment" {
  description = "Deployment environment (eg: dev, staging, prod). Used in resource names and tags."
  type        = string
  default     = "dev"
}

variable "aws_cloudwatch_log_group" {
  description = "Name of the AWS CloudWatch log group forwarding data to central monitoring."
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "Admin password used for the Grafana deployment (sensitive)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "prometheus_retention" {
  description = "Prometheus retention period in days (in workspace configuration)."
  type        = number
  default     = 15
}

variable "opensearch_enabled" {
  description = "Whether to provision an OpenSearch domain for centralized logs/search."
  type        = bool
  default     = true
}

variable "enable_alerting" {
  description = "Provision cross-account or cross-cloud alerting hooks (SNS, alarms)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to AWS resources created by this module."
  type        = map(string)
  default     = {}
}

