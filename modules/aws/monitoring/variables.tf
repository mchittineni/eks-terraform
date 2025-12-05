variable "cluster_name" {
  description = "Name of the EKS cluster to monitor"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch log alerts"
  type        = bool
  default     = true
}

variable "enable_prometheus" {
  description = "Enable Amazon Managed Prometheus"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for SNS notifications"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to monitoring resources"
  type        = map(string)
  default     = {}
}
