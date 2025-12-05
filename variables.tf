# ==================== General Variables ====================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "AWS-Infra"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "owner_email" {
  description = "Email of the infrastructure owner"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", var.owner_email))
    error_message = "The email address is not valid. Please provide a properly formatted email (e.g. user@example.com)."
  }
}

variable "alert_email" {
  description = "Email for receiving alerts"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", var.alert_email))
    error_message = "The email address is not valid. Please provide a properly formatted email (e.g. user@example.com)."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = true
}

variable "enable_aws" {
  description = "Toggle AWS infrastructure modules."
  type        = bool
  default     = true
}

# ==================== AWS Variables ====================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "aws_public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "aws_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "aws_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "aws_node_count" {
  description = "Number of worker nodes in EKS cluster"
  type        = number
  default     = 6
  validation {
    condition     = var.aws_node_count >= 2 && var.aws_node_count <= 10
    error_message = "Node count must be between 2 and 10."
  }
}

variable "aws_db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "appdb"
}

variable "aws_db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "aws_db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "aws_db_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 100
}

variable "aws_db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

# ==================== Monitoring Variables ====================

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  validation {
    condition = (
      # If monitoring is disabled, skip password validation
      !var.enable_monitoring || (
        length(var.grafana_admin_password) >= 12 &&
        can(regex("[A-Z]", var.grafana_admin_password)) &&
        can(regex("[a-z]", var.grafana_admin_password)) &&
        can(regex("[0-9]", var.grafana_admin_password)) &&
        can(regex("[^A-Za-z0-9]", var.grafana_admin_password))
      )
    )
    error_message = <<-EOT
The Grafana admin password must be at least 12 characters long and include:
  - at least one uppercase letter
  - at least one lowercase letter
  - at least one number
  - at least one special character
EOT
  }
}

variable "prometheus_retention_days" {
  description = "Data retention period for Prometheus in days"
  type        = number
  default     = 15
  validation {
    condition     = var.prometheus_retention_days >= 7 && var.prometheus_retention_days <= 90
    error_message = "Retention period must be between 7 and 90 days."
  }
}

# ==================== Tags ====================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Project   = "AWS Infrastructure"
    ManagedBy = "Terraform"
  }
}