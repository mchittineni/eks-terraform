# EKS Terraform - Troubleshooting Guide

## Deployment Issues

### Issue: Terraform state lock

**Symptoms:**
```
Error: Error acquiring the state lock
Error message: ConditionalCheckFailedException
```

**Solutions:**
```bash
# List and identify the lock ID
aws dynamodb scan --table-name terraform-locks

# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Retry terraform operation
terraform plan
```

### Issue: AWS provider authentication failed

**Symptoms:**
```
Error: error configuring Terraform AWS Provider: no valid credential sources found
```

**Solutions:**

1. **Check AWS credentials:**
```bash
# Verify credentials are configured
aws sts get-caller-identity

# If this fails, configure AWS CLI
aws configure
```

2. **Verify IAM permissions:**
```bash
# Check current user permissions
aws iam get-user

# Required permissions for this deployment:
# - ec2:*, eks:*, rds:*, iam:*, s3:*, dynamodb:*
```

### Issue: `Failed to get existing workspaces` / `NoSuchBucket`

**Symptoms:**
```
Error: Failed to get existing workspaces: error listing S3 Bucket Objects:
NoSuchBucket: The specified bucket does not exist
```

**Solutions:**
```bash
# Create backend bucket
export TF_BACKEND_BUCKET="terraform-state-eks-$(date +%s)"
export TF_BACKEND_REGION="us-east-1"
./scripts/ensure_backend_bucket.sh

# Verify bucket was created
aws s3 ls | grep terraform-state

# Reconfigure terraform
terraform init -reconfigure
```

### Issue: Module not found

**Symptoms:**
```
Error: module not found
Error: source "./modules/..." not found
```

**Solutions:**
```bash
# Verify module directory structure
ls -la modules/
ls -la modules/aws/

# Upgrade and re-initialize modules
terraform init -upgrade
```

## Kubernetes/EKS Issues

### Issue: Cannot connect to EKS cluster

**Symptoms:**
```
The connection to the server was refused
Unable to connect to the server
```

**Solutions:**

1. **Update kubeconfig:**
```bash
# Get cluster name from terraform output
TERRAFORM_CLUSTER=$(terraform output -raw eks_cluster_name)

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name $TERRAFORM_CLUSTER

# Verify connection
kubectl cluster-info
```

2. **Verify cluster is running:**
```bash
aws eks describe-cluster --name $TERRAFORM_CLUSTER --query 'cluster.status'
# Should return: ACTIVE
```

### Issue: Nodes are not ready

**Symptoms:**
```
NAME                             STATUS     ROLES    AGE
ip-10-0-*.compute.internal       NotReady   <none>   5m
```

**Solutions:**

1. **Check node status:**
```bash
# Get detailed node status
kubectl describe node <node-name>

# Check node logs
kubectl logs -n kube-system -l k8s-app=aws-node
```

2. **Common causes:**
   - CNI plugin not ready: Check AWS VPC CNI pods
   - Security group issues: Verify node security group
   - Insufficient resources: Check node capacity with `kubectl top nodes`

### Issue: Pods stuck in `Pending` state

**Symptoms:**
```
NAME                    READY   STATUS    RESTARTS   AGE
my-pod                  0/1     Pending   0          10m
```

**Solutions:**

1. **Check pod events:**
```bash
kubectl describe pod <pod-name> -n <namespace>
```

2. **Common causes:**
   - Insufficient node resources: Scale up with `terraform apply -var='aws_node_count=8'`
   - Node affinity mismatch: Verify node labels with `kubectl get nodes --show-labels`

## Monitoring Issues

### Issue: Cannot access Grafana

**Symptoms:**
```
Connection refused or timeout
```

**Solutions:**

1. **Verify Grafana pod is running:**
```bash
kubectl get pods -n monitoring
```

2. **Get load balancer URL:**
```bash
kubectl get svc -n monitoring grafana
```

3. **Port forward if needed:**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# Access at http://localhost:3000
```

### Issue: Prometheus not collecting metrics

**Symptoms:**
- No metrics in Prometheus
- Empty graphs in Grafana

**Solutions:**

1. **Verify Prometheus pod:**
```bash
kubectl get pods -n monitoring -l app=prometheus
kubectl logs -n monitoring -l app=prometheus --tail=50
```

2. **Check targets (in Prometheus UI):**
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Navigate to Status > Targets
```

## Database Issues

### Issue: Cannot connect to RDS database

**Symptoms:**
```
Connection timeout
Access denied
```

**Solutions:**

1. **Get RDS endpoint:**
```bash
terraform output -raw rds_endpoint
```

2. **Check security group:**
```bash
# Verify RDS security group allows access from EKS nodes
aws ec2 describe-security-groups --group-ids <rds-sg-id>
```

3. **Test connectivity:**
```bash
# From EKS node via kubectl
kubectl run debug --image=busybox --rm -it -- sh
nc -zv <RDS_ENDPOINT> 3306
```

## Terraform Validation Issues

### Issue: Variable validation failed

**Symptoms:**
```
Error: Invalid environment
Error: The email address is not valid
Error: Node count must be between 2 and 10
```

**Solutions:**

1. **Environment validation:**
```bash
# Valid values: dev, staging, production
terraform apply -var='environment=dev'
```

2. **Email validation:**
```bash
terraform apply -var='owner_email=user@example.com'
```

3. **Node count validation:**
```bash
# Must be between 2-10
terraform apply -var='aws_node_count=6'
```

4. **Grafana password validation:**
```bash
# Min 12 chars: uppercase + lowercase + number + special char
terraform apply -var='grafana_admin_password=SecurePass123!@#'
```

## Getting Help

### Useful Commands for Debugging

```bash
# Terraform debugging
TF_LOG=DEBUG terraform plan 2>&1 | tee terraform-debug.log

# Kubernetes cluster info
kubectl cluster-info dump --output-directory=cluster-dump

# EKS cluster status
aws eks describe-cluster --name <cluster-name> --query 'cluster.{Status:status,Endpoint:endpoint}'
```

### Documentation and Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
