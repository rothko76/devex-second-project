# modules/security_groups/variables.tf
variable "vpc_id" {
  description = "VPC ID to associate the security groups with"
  type        = string
}
