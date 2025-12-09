locals {
  merged_tags = merge(
    {
      Environment = var.environment
      Component   = "rds"
    },
    var.tags
  )
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

# ==================== Random Password ====================
resource "random_password" "master" {
  length           = 20
  override_special = "!@#%^*-_=+"
  special          = true
  min_upper        = 2
  min_lower        = 4
  min_numeric      = 4
  min_special      = 2
}

resource "random_id" "bucket" {
  byte_length = 4
}

# ==================== RDS Security Rules ====================
resource "aws_db_subnet_group" "this" {
  name        = "${var.db_name}-${var.environment}-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "RDS subnet group for ${var.db_name} in ${var.environment}"
  tags        = local.merged_tags
}

resource "aws_security_group" "db" {
  name        = "${var.db_name}-${var.environment}-db-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow Postgres traffic from within the VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.merged_tags
}

resource "aws_db_parameter_group" "postgres" {
  name        = "${var.db_name}-${var.environment}-pg"
  family      = "postgres14"
  description = "Custom parameter group enforcing SSL"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = local.merged_tags
}

# ==================== RDS IAM : Monitoring ====================
resource "aws_iam_role" "rds_monitoring" {
  name        = "${var.db_name}-${var.environment}-monitoring-role"
  description = "IAM role used by RDS Enhanced Monitoring for ${var.db_name} in ${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ==================== RDS Backup S3 ====================
resource "aws_s3_bucket" "backups" {
  bucket = lower(replace("${var.db_name}-${var.environment}-${random_id.bucket.hex}", "_", "-"))
  tags   = local.merged_tags
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# ==================== RDS Instance ====================
resource "aws_db_instance" "this" {
  identifier                          = "${var.db_name}-${var.environment}"
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.allocated_storage + 100
  engine                              = "postgres"
  engine_version                      = "14"
  instance_class                      = var.instance_class
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [aws_security_group.db.id]
  db_name                             = var.db_name
  username                            = var.db_username
  password                            = random_password.master.result
  multi_az                            = var.multi_az
  storage_encrypted                   = true
  kms_key_id                          = null
  backup_retention_period             = var.backup_retention_days
  deletion_protection                 = var.environment == "production"
  skip_final_snapshot                 = var.environment == "dev"
  final_snapshot_identifier           = var.environment == "dev" ? null : "${var.db_name}-${var.environment}-final"
  performance_insights_enabled        = var.performance_insights_enabled
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_monitoring.arn
  publicly_accessible                 = false
  apply_immediately                   = true
  parameter_group_name                = aws_db_parameter_group.postgres.name
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true

  tags = local.merged_tags
}

# ==================== RDS Database Secrets ====================
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.db_name}-${var.environment}-db-credentials"
  description = "Database credentials for ${var.db_name} in ${var.environment} environment"
  tags        = local.merged_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master.result
    endpoint = aws_db_instance.this.address
    port     = aws_db_instance.this.port
  })
}
