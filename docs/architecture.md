# EKS Terraform Infrastructure - Architecture Overview

## Visual Architecture Diagram

The infrastructure architecture diagram below is generated automatically from the Terraform plan using [tf-arch-diagram-generator](https://github.com/mchittineni/tf-arch-diagram-generator).

![AWS EKS Architecture Diagram](architecture.svg)

> **Interactive Viewer**: Run `./scripts/generate_diagram.sh --serve` to explore the architecture interactively in your browser with resource inspection and dependency tracing.

---

## High-Level Architecture

This infrastructure provides a complete, production-grade AWS-based Kubernetes solution featuring:
- **AWS Region**: Configurable (default: `us-east-1`)
- **Kubernetes Cluster**: Amazon EKS v1.36+ with auto-managed control plane
- **Worker Nodes**: Amazon Linux 2023 (`AL2023_x86_64_STANDARD`) managed node group with auto-scaling (2-10 nodes)
- **Multi-AZ Deployment**: High availability across 3 Availability Zones (`us-east-1a`, `us-east-1b`, `us-east-1c`)
- **Managed Database**: Amazon RDS PostgreSQL 16 Multi-AZ instance with automated backups and encryption
- **Observability Stack**: Amazon Managed Service for Prometheus (AMP) and Amazon Managed Grafana (AMG) / centralized monitoring

---

## Core Components

### 1. Networking Module (`modules/aws/networking`)
- **VPC**: Dedicated CIDR block (default: `10.0.0.0/16`) with DNS hostnames and support enabled
- **Public Subnets**: 3 subnets (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`) tagged with `kubernetes.io/role/elb = 1` for internet-facing ALBs
- **Private Subnets**: 3 subnets (`10.0.11.0/24`, `10.0.12.0/24`, `10.0.13.0/24`) tagged with `kubernetes.io/role/internal-elb = 1` for internal workloads and RDS
- **NAT Gateways**: High-availability multi-AZ egress via dedicated Elastic IPs per availability zone
- **Internet Gateway**: Public subnet edge routing
- **Route Tables**: Strict public/private separation with least-privilege egress routes

### 2. Compute Module (`modules/aws/compute`)
- **EKS Cluster**: Managed Kubernetes control plane (default: v1.36) with private and public endpoint access
- **Managed Node Group**:
  - AMI: Amazon Linux 2023 (`AL2023_x86_64_STANDARD`)
  - Instance Type: Configurable (default: `t3.medium`)
  - Auto-scaling: Configurable node count (default: 6 nodes, bounds: 2-10)
  - Subnets: Deployed exclusively in private subnets for security
- **IAM Roles**: Least-privilege roles for control plane (`AmazonEKSClusterPolicy`, `AmazonEKSServicePolicy`) and worker nodes (`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`)
- **Security Groups**: Granular control plane and node security groups restricting port 443 API access

### 3. Database Module (`modules/aws/database`)
- **RDS PostgreSQL Instance**: Version 16 LTS with Multi-AZ failover capability
- **Parameter Group**: Custom `postgres16` parameter group enforcing SSL (`rds.force_ssl = 1`)
- **Storage**: 100 GB allocated GP3 storage with auto-scaling storage enabled
- **Security**: Encrypted at rest via AWS KMS / SSE, private subnet isolation, credentials stored in AWS Secrets Manager
- **Backups**: Automated daily snapshots + dedicated S3 backup bucket with versioning and public access block

### 4. Monitoring Stack (`modules/aws/monitoring` & `modules/monitoring/centralized`)
- **CloudWatch Logs**: EKS control plane logging (API, audit, authenticator, controllerManager, scheduler)
- **Prometheus**: Amazon Managed Service for Prometheus workspace for cluster and application metrics
- **Grafana**: Centralized visualization workspace with role-based IAM integration and secure admin password rotation
- **Alerting**: Amazon SNS topic subscriptions for critical infrastructure alarms and error spikes

---

## Automated Diagram Generation

Architecture diagrams are continuously generated in CI/CD and locally:

```bash
# Generate architecture.svg from Terraform plan
./scripts/generate_diagram.sh dev -o docs/architecture.svg

# Or generate and open interactive canvas in browser
./scripts/generate_diagram.sh dev --serve
```

Diagrams are produced by **[tf-arch-diagram-generator](https://github.com/mchittineni/tf-arch-diagram-generator)** directly from `terraform show -json` output, capturing VPC nesting, subnets, compute, databases, and network connectors without browser dependencies.