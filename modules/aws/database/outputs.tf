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
