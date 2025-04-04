# modules/security_groups/outputs.tf
output "eks_sg_id" {
  description = "The security group ID for EKS"
  value       = aws_security_group.eks_sg.id
}

output "rds_sg_id" {
  description = "The security group ID for RDS"
  value       = aws_security_group.rds_sg.id
}

output "alb_sg_id" {
  description = "The security group ID for ALB"
  value       = aws_security_group.alb_sg.id
}

output "kinesis_sg_id" {
  description = "The security group ID for Kinesis"
  value       = aws_security_group.kinesis_sg.id
}
