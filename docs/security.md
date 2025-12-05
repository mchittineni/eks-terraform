# EKS Terraform - Security Guide

## Security Overview

This infrastructure implements multiple layers of security following AWS best practices and the principle of least privilege.

## Secrets Management

### Sensitive Variables

**Never commit `terraform.tfvars` to version control!** This file contains:
- `aws_db_username` - RDS master username
- `grafana_admin_password` - Grafana admin credentials

### Best Practices

```bash
# 1. Use environment variables for sensitive values
export TF_VAR_grafana_admin_password="YourStrongPassword123!"

# 2. Keep terraform.tfvars in .gitignore (already configured)
cat .gitignore | grep terraform.tfvars

# 3. Store secrets securely outside version control
# Option A: AWS Secrets Manager
# Option B: HashiCorp Vault
# Option C: Environment variables
# Option D: Terraform Cloud/Enterprise remote state

# 4. Rotate credentials regularly
# Update grafana_admin_password in terraform.tfvars and re-apply
```

## Network Security

### Network Segmentation

**Public Subnets** (3 AZs)
- NAT Gateways for outbound traffic
- Internet Gateway for inbound traffic
- Load Balancers for service exposure
- No EKS nodes or databases

**Private Subnets** (3 AZs)
- EKS worker nodes
- RDS database
- Prometheus and Grafana pods
- No direct internet access (egress via NAT)

### Security Groups

**EKS Security Group:**
- Allow ingress from load balancers
- Allow pod-to-pod communication
- Restrict to necessary ports only
- Deny all by default

**RDS Security Group:**
- Allow ingress only from EKS nodes on port 3306 (MySQL) or 5432 (PostgreSQL)
- No direct internet access
- Encryption in transit with SSL/TLS

**Load Balancer Security Group:**
- HTTP/HTTPS ingress from anywhere (0.0.0.0/0)
- Egress to EKS nodes only

## IAM Security

### Principle of Least Privilege

**EKS Node IAM Role:**
- EC2 permissions for node management
- ECR permissions for container images
- CloudWatch permissions for logging
- VPC CNI permissions for networking
- No administrative or wildcard permissions

**EKS Cluster IAM Role:**
- Service-specific permissions only
- VPC management
- Security group management
- No access to data resources

### Credential Rotation

```bash
# RDS master password rotation
terraform taint aws_db_instance.main
terraform apply  # Forces new password

# Grafana admin password rotation
terraform apply -var='grafana_admin_password=NewPassword123!'
```

## Data Encryption

### Encryption at Rest

**RDS Database:**
- AWS KMS encryption enabled by default
- Customer-managed keys recommended for production

**Terraform State (S3):**
- Server-side encryption (SSE-S3) enabled
- Versioning enabled for recovery
- MFA delete recommended for production

**EBS Volumes (Node Storage):**
- Encryption enabled for all volumes
- AWS KMS keys

### Encryption in Transit

**Pod-to-Pod Communication:**
- Enabled by default within VPC
- Implement TLS for inter-pod communication

**RDS Connection:**
- SSL/TLS enforced

**Load Balancer to Pods:**
- HTTPS/TLS termination at load balancer
- Internal pod communication via private network

## Security Checklist

Before deploying to production:

- [ ] Change all default credentials
- [ ] Enable MFA for AWS console access
- [ ] Configure AWS CloudTrail for audit logging
- [ ] Enable VPC Flow Logs for network monitoring
- [ ] Set up CloudWatch alarms for security events
- [ ] Implement pod security policies
- [ ] Configure network policies for pod traffic
- [ ] Enable EKS control plane logging
- [ ] Set up RBAC for Kubernetes access
- [ ] Implement secrets management (AWS Secrets Manager or Vault)
- [ ] Run security scanning tools (tfsec, Checkov)
- [ ] Configure backup and disaster recovery
- [ ] Enable encryption for all data at rest and in transit

## Compliance Scanning

```bash
# Scan Terraform configuration for security issues
tfsec .

# Run policy checks with Checkov
checkov -d . --framework terraform
```

## Additional Resources

- [AWS EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
