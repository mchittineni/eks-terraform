# EKS Terraform Infrastructure - Architecture Overview

## High-Level Architecture

This infrastructure provides a complete AWS-based Kubernetes solution with:
- **AWS Region**: Configurable (default: us-east-1)
- **Kubernetes Cluster**: Amazon EKS (Elastic Kubernetes Service)
- **Multi-AZ Deployment**: High availability across multiple availability zones
- **Monitoring Stack**: Prometheus and Grafana for observability
- **Database**: Amazon RDS for persistent data

## Core Components

### Networking Module (`modules/aws/networking`)
- **VPC**: Custom CIDR block (default: 10.0.0.0/16)
- **Public Subnets**: 3 subnets for NAT gateways and load balancers
- **Private Subnets**: 3 subnets for EKS nodes and internal resources
- **Availability Zones**: Distributed across 3 AZs for high availability
- **NAT Gateways**: For secure outbound traffic from private subnets
- **Internet Gateway**: For public subnet internet access
- **Route Tables**: Properly configured for public/private routing

### Compute Module (`modules/aws/compute`)
- **EKS Cluster**: Managed Kubernetes control plane
- **Node Groups**: Auto-scaling worker nodes (default: 6 nodes, t3.medium)
- **IAM Roles**: Proper permissions for nodes and cluster
- **Security Groups**: Network access control for cluster communication
- **Auto Scaling**: Configurable node count (2-10 nodes)

### Database Module (`modules/aws/database`)
- **RDS Instance**: Multi-AZ capable for high availability
- **Instance Type**: Configurable (default: db.t3.medium)
- **Storage**: Allocated storage in GB (default: 100 GB)
- **Multi-AZ**: Automatic failover capability
- **Backups**: Automated daily backups with configurable retention
- **Security**: Encrypted at rest and in transit

### Monitoring Module (`modules/monitoring/centralized`)
- **Prometheus**: Metrics collection and storage (retention: 7-90 days)
- **Grafana**: Visualization and dashboards
- **Admin Password**: Strong password validation enforced
- **Data Persistence**: Configured storage for metrics retention
- **Alerting**: Integration capabilities for notifications

## Key Features

### High Availability
- Multi-AZ deployment across 3 availability zones
- Auto-scaling node groups for workload demands
- Multi-AZ RDS with automatic failover
- Load balancer for service distribution

### Security
- Network segmentation with public/private subnets
- IAM roles following principle of least privilege
- Encryption at rest and in transit
- Security groups for network access control
- VPC isolation and control

### Observability
- Prometheus for metrics collection
- Grafana dashboards for visualization
- Configurable retention periods (7-90 days)
- Integration with AWS CloudWatch

### Scalability
- Configurable node count (2-10 nodes)
- Auto-scaling policies for workloads
- RDS storage capacity management
- Prometheus data retention optimization