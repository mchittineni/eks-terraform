variable "aws_cloudwatch_log_group" {
  description = "Name of the AWS CloudWatch log group forwarding data"
  type        = string
}

variable "grafana_admin_password" {
  description = "Admin password used for the Grafana deployment"
  type        = string
  sensitive   = true
}

variable "prometheus_retention" {
  description = "Prometheus retention period in days"
  type        = number
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "enable_alerting" {
  description = "Provision cross-cloud alerting hooks"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to stamp on AWS resources"
  type        = map(string)
  default     = {}
}
