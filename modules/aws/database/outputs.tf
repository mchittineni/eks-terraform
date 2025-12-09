output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.this.address
  sensitive   = true
}

output "db_identifier" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.this.id
}

output "db_port" {
  description = "Port number for database connections"
  value       = aws_db_instance.this.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
  sensitive   = true
}

output "s3_bucket_name" {
  description = "Bucket used for logical backups"
  value       = aws_s3_bucket.backups.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "db_security_group_id" {
  description = "Security group protecting the RDS instance"
  value       = aws_security_group.db.id
}

output "rds_monitoring_role_arn" {
  description = "ARN of the IAM role used for RDS enhanced monitoring"
  value       = aws_iam_role.rds_monitoring.arn
}

output "s3_backup_bucket_arn" {
  description = "ARN of the S3 bucket for backups"
  value       = aws_s3_bucket.backups.arn
}
