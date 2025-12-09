// ==================== Terraform Configuration ====================
// Defines the required Terraform version, providers, and the remote S3 state backend.
terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  // Configuration for the S3 backend to store the Terraform state file securely.
  backend "s3" {
    bucket       = "terraform-state-multicloud-infra"
    key          = "global/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

// ==================== Provider Configurations ====================
// Configuration for the AWS Provider.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Application = "AWS-EKS-Terraform"
      Owner       = var.owner_email
      CostCenter  = var.cost_center
    }
  }
}

// ==================== AWS Secrets Manager (Data and Resource) ====================
// Data source to reference the existing AWS Secrets Manager secret named "Terraform".
data "aws_secretsmanager_secret" "Terraform" {
  name = "Terraform"
}

// Resource to create a new version for the 'Terraform' secret.
// This stores root-level metadata (project, environment, owner) as a JSON string.
// This data can be consumed by other services or CI/CD pipelines.
resource "aws_secretsmanager_secret_version" "Terraform" {
  secret_id = data.aws_secretsmanager_secret.Terraform.id
  secret_string = jsonencode({
    project_name = var.project_name
    environment  = var.environment
    owner_email  = var.owner_email
  })
}

// ==================== AWS Infrastructure Modules ====================
// Module for configuring the VPC, subnets (public/private), Internet Gateway, and NAT Gateways.
module "aws_networking" {
  source               = "./modules/aws/networking"
  vpc_cidr             = var.aws_vpc_cidr
  availability_zones   = var.aws_availability_zones
  public_subnet_cidrs  = var.aws_public_subnet_cidrs
  private_subnet_cidrs = var.aws_private_subnet_cidrs
  environment          = var.environment
  project_name         = var.project_name
}

// Module for provisioning the EKS cluster and its worker nodes (EC2 instances or managed node groups).
module "aws_compute" {
  source             = "./modules/aws/compute"
  vpc_id             = module.aws_networking.vpc_id
  private_subnet_ids = module.aws_networking.private_subnet_ids
  public_subnet_ids  = module.aws_networking.public_subnet_ids
  instance_type      = var.aws_instance_type
  cluster_name       = "${var.project_name}-${var.environment}-eks"
  node_count         = var.aws_node_count
  environment        = var.environment
}

// Module for deploying an Amazon RDS relational database instance (e.g., PostgreSQL, MySQL).
module "aws_database" {
  source             = "./modules/aws/database"
  vpc_id             = module.aws_networking.vpc_id
  private_subnet_ids = module.aws_networking.private_subnet_ids
  db_name            = var.aws_db_name
  db_username        = var.aws_db_username
  instance_class     = var.aws_db_instance_class
  allocated_storage  = var.aws_db_allocated_storage
  multi_az           = var.aws_db_multi_az
  environment        = var.environment
}

// Module for setting up AWS-native monitoring resources (e.g., CloudWatch Log Groups, SNS for alerting).
module "aws_monitoring" {
  source                 = "./modules/aws/monitoring"
  cluster_name           = module.aws_compute.cluster_name
  environment            = var.environment
  enable_cloudwatch_logs = var.enable_monitoring
  enable_prometheus      = var.enable_monitoring
  alert_email            = var.alert_email
}

// ==================== Centralized Monitoring Module ====================
// This module sets up centralized monitoring tools (e.g., Grafana, Prometheus).
module "centralized_monitoring" {
  source = "./modules/monitoring/centralized"
  // Conditionally pass the AWS CloudWatch Log Group name only if AWS is enabled.
  aws_cloudwatch_log_group = var.enable_aws ? module.aws_monitoring.log_group_name : null
  grafana_admin_password   = var.grafana_admin_password
  prometheus_retention     = var.prometheus_retention_days
  environment              = var.environment
}