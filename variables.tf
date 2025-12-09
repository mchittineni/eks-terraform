# ==================== General Configuration Variables ====================

variable "project_name" {
  description = "The descriptive name of the project. Used in resource naming and tagging."
  type        = string
  default     = "AWS-Infra"
}

variable "environment" {
  description = "The target environment (e.g., dev, staging, production)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, or production."
  }
}

variable "owner_email" {
  description = "The email address of the primary infrastructure owner for administrative purposes and tagging."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", var.owner_email))
    error_message = "The owner email address is not valid (e.g., user@example.com)."
  }
}

variable "cost_center" {
  description = "The cost center code for billing and resource tracking purposes."
  type        = string
  default     = "1A2B3C4D5E6F7G8H9I"
}

variable "enable_aws" {
  description = "If true, provision the AWS infrastructure (VPC, EKS, RDS). Setting to false disables AWS modules."
  type        = bool
  default     = true
}

# ==================== AWS Cloud Variables ====================

### Region & Networking

variable "aws_region" {
  description = "The AWS region where all resources will be provisioned."
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "The main CIDR block for the AWS VPC (e.g., 10.0.0.0/16)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_availability_zones" {
  description = "A list of Availability Zones to use for resource placement."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "aws_public_subnet_cidrs" {
  description = "A list of CIDR blocks for public subnets (e.g., for Load Balancers and NAT Gateways)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "aws_private_subnet_cidrs" {
  description = "A list of CIDR blocks for private subnets (e.g., for EKS nodes and RDS)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

### Compute (EKS)

variable "aws_instance_type" {
  description = "The EC2 instance type to use for the EKS worker nodes (e.g., t3.medium)."
  type        = string
  default     = "t3.medium"
}

variable "aws_node_count" {
  description = "The desired number of worker nodes in the EKS cluster."
  type        = number
  default     = 6
  validation {
    condition     = var.aws_node_count >= 2 && var.aws_node_count <= 10
    error_message = "Node count must be between 2 and 10 for this environment."
  }
}

### Database (RDS)

variable "aws_db_name" {
  description = "The name of the initial database to be created in the RDS instance."
  type        = string
  default     = "appdb"
}

variable "aws_db_username" {
  description = "The master username for the RDS database."
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "aws_db_instance_class" {
  description = "The compute and memory capacity of the RDS instance (e.g., db.t3.medium)."
  type        = string
  default     = "db.t3.medium"
}

variable "aws_db_allocated_storage" {
  description = "The size of the database storage volume in Gigabytes (GB)."
  type        = number
  default     = 100
}

variable "aws_db_multi_az" {
  description = "If true, enables Multi-AZ deployment for high availability and failover."
  type        = bool
  default     = true
}

# ==================== Monitoring Variables ====================

variable "enable_monitoring" {
  description = "If true, provision the centralized monitoring stack (Prometheus, Grafana)."
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "The email address for receiving operational alerts from the monitoring system."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", var.alert_email))
    error_message = "The alert email address is not valid (e.g., alert-user@example.com)."
  }
}

variable "grafana_admin_password" {
  description = "The initial administrator password for the Grafana dashboard."
  type        = string
  sensitive   = true
  validation {
    condition = (
      // Skip password validation if monitoring is explicitly disabled
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
  description = "The data retention period for Prometheus metrics storage, specified in days."
  type        = number
  default     = 15
  validation {
    condition     = var.prometheus_retention_days >= 7 && var.prometheus_retention_days <= 90
    error_message = "Retention period must be between 7 and 90 days to manage storage costs and performance."
  }
}
