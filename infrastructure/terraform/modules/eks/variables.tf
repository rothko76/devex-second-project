variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "eks_managed_node_groups" {
  description = "Managed node groups for the EKS cluster"
  type        = map(any)
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
}

variable "tags" {
  description = "Tags for the EKS cluster"
  type        = map(string)
}