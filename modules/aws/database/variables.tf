variable "vpc_id" {
  description = "VPC identifier hosting the database"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets that form the DB subnet group"
  type        = list(string)
}

variable "db_name" {
  description = "Application database name"
  type        = string
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "backup_retention_days" {
  description = "Backup retention period"
  type        = number
  default     = 7
}

variable "performance_insights_enabled" {
  description = "Enable RDS Performance Insights"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Optional tags to merge with the defaults"
  type        = map(string)
  default     = {}
}
