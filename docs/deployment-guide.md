# EKS Terraform - Deployment Guide

## Prerequisites

Before deploying, ensure you have:

- **Terraform** >= 1.13.0 ([Install](https://www.terraform.io/downloads.html))
- **AWS CLI** configured with credentials ([Setup](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **kubectl** installed for Kubernetes management ([Install](https://kubernetes.io/docs/tasks/tools/))
- **AWS Account** with appropriate permissions (EC2, EKS, RDS, VPC, IAM)
- **Valid email addresses** for owner and alerts

## Step-by-Step Deployment

### Step 1: Clone and Navigate to Repository

```bash
git clone https://github.com/mchittineni/eks-terraform.git
cd eks-terraform
```

### Step 2: Configure Terraform Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Required configurations:**
- `environment`: dev, staging, or production
- `owner_email`: Your email (must be valid format)
- `alert_email`: Alert recipient email (must be valid format)
- `aws_node_count`: 2-10 nodes (recommended: 6)
- `grafana_admin_password`: Min 12 chars, must include uppercase, lowercase, number, special char
- `aws_region`: AWS region for deployment

**Example values:**
```hcl
project_name          = "AWS-Infra"
environment            = "dev"
owner_email            = "your.email@example.com"
alert_email            = "alerts@example.com"
aws_region             = "us-east-1"
aws_node_count         = 6
grafana_admin_password = "GrafanaAdmin123!"
```

### Step 3: Bootstrap Backend Storage (One-Time)

This creates the S3 bucket for Terraform state:

```bash
# Optional: Set custom backend configuration
export TF_BACKEND_BUCKET="eks-terraform-state-$(date +%s)"
export TF_BACKEND_REGION="us-east-1"

# Run bootstrap script
./scripts/ensure_backend_bucket.sh
```

**What this does:**
- Creates S3 bucket for remote state
- Enables versioning for state recovery
- Configures access logs
- Enables encryption

### Step 4: Initialize Terraform

```bash
# Initialize Terraform with backend configuration
./scripts/init.sh
```

Or manually:
```bash
terraform init
```

### Step 5: Plan the Deployment

Review what resources will be created:

```bash
terraform plan -out=tfplan
```

**This will show:**
- VPC and networking resources (3 public + 3 private subnets)
- EKS cluster and node groups (6 nodes)
- RDS database instance
- Prometheus and Grafana
- IAM roles and security groups

### Step 6: Apply the Configuration

Deploy the infrastructure:

```bash
terraform apply tfplan
```

**Expected deployment time:** 15-25 minutes

**What gets created:**
- AWS VPC with 3-AZ deployment
- EKS Kubernetes cluster
- 6 t3.medium worker nodes
- Multi-AZ RDS database
- Prometheus and Grafana stack
- All supporting networking and IAM resources

### Step 7: Configure kubectl (After Deployment)

Once the EKS cluster is deployed:

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>

# Verify connection
kubectl get nodes
```

## Environment-Specific Deployments

### Using Terraform Workspaces

Keep state isolated per environment:

```bash
# Initialize workspaces
./scripts/init.sh

# Deploy to specific environment
./scripts/deploy.sh dev
./scripts/deploy.sh staging
./scripts/deploy.sh production
```

Each workspace maintains separate state and resources.

## Post-Deployment

### Access Grafana

1. Get the Grafana load balancer URL:
```bash
kubectl get svc -n monitoring grafana
```

2. Access dashboard at `http://<LoadBalancer-URL>`
3. Default credentials:
   - Username: `admin`
   - Password: (from `grafana_admin_password`)

### Access Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Access at http://localhost:9090
```

### Verify RDS Connection

```bash
# Get RDS endpoint
terraform output rds_endpoint

# Connect via mysql/psql client
mysql -h <rds-endpoint> -u dbadmin -p
```

## Destroying Infrastructure

To remove all resources:

```bash
# Using script
./scripts/destroy.sh

# Or manually
terraform destroy
```

**Warning:** This will delete all resources including the RDS database. Ensure backups are created first.

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues and solutions.
