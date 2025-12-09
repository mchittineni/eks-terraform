// The Terraform block remains standard as it defines requirements and state backend.
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

  backend "s3" {
    bucket       = "terraform-state-multicloud-infra"
    key          = "global/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

// ==================== Provider Configurations ====================
// Providers are only configured if their respective 'enable' variable is true.

provider "aws" {
  # count  = var.enable_aws ? 1 : 0
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "AWS-EKS-Terraform"
      Owner       = var.owner_email
    }
  }
}
data "aws_secretsmanager_secret" "Terraform" {
  name = "Terraform"
}

resource "aws_secretsmanager_secret_version" "Terraform" {
  secret_id = data.aws_secretsmanager_secret.Terraform.id
  secret_string = jsonencode({
    project_name = var.project_name
    environment  = var.environment
    owner_email  = var.owner_email
  })
}


// ==================== AWS Infrastructure ====================
// AWS modules only run if var.enable_aws is true.
// Note: Outputs are accessed using [0] because the module is now a list.

module "aws_networking" {
  source               = "./modules/aws/networking"
  vpc_cidr             = var.aws_vpc_cidr
  availability_zones   = var.aws_availability_zones
  public_subnet_cidrs  = var.aws_public_subnet_cidrs
  private_subnet_cidrs = var.aws_private_subnet_cidrs
  environment          = var.environment
  project_name         = var.project_name
}

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

module "aws_monitoring" {
  source                 = "./modules/aws/monitoring"
  cluster_name           = module.aws_compute.cluster_name
  environment            = var.environment
  enable_cloudwatch_logs = var.enable_monitoring
  enable_prometheus      = var.enable_monitoring
  alert_email            = var.alert_email
}

// ==================== Cloud Monitoring ====================
// Inputs are conditionally set to the module output or null based on the 'enable' variables.

module "centralized_monitoring" {
  source = "./modules/monitoring/centralized"
  // AWS outputs are accessed with and set to null if disabled
  aws_cloudwatch_log_group    = var.enable_aws ? module.aws_monitoring.log_group_name : null
  grafana_admin_password      = var.grafana_admin_password
  prometheus_retention        = var.prometheus_retention_days
  environment                 = var.environment
}