output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "flow_log_group_name" {
  description = "CloudWatch Log Group name used for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_log.name
}

output "flow_log_role_arn" {
  description = "IAM role ARN used by VPC Flow Logs"
  value       = aws_iam_role.flow_log.arn
}

output "vpc_endpoint_sg_id" {
  description = "Security group ID used for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}