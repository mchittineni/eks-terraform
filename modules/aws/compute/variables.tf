variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/production)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the control plane and load balancers"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.29"
}

variable "instance_type" {
  description = "EC2 instance type for managed node groups"
  type        = string
}

variable "node_count" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "tags" {
  description = "Optional tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}
