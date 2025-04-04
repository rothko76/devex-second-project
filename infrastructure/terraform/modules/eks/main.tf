module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.16.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  eks_managed_node_groups = var.eks_managed_node_groups
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  
 # Important: Disable the default aws-auth config map management
  manage_aws_auth_configmap = false

  tags = var.tags
}