# variables.tf
variable "region" {
  description = "AWS region where the cluster will be deployed"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  default     = "devex-2nd-ex-eks-cluster"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type for the worker nodes"
  default     = "t3.medium"
}

variable "testing_instance_type" {
  description = "EC2 instance for testing purposes"
  default     = "t3.micro"
}

variable "lambda_bucket" {
  description = "S3 bucket for Lambda function code"
  default     = "devex-2nd-ex-lambda-bucket"
}

variable "lambda_" {
  description = "S3 bucket for Lambda function code"
  default     = "devex-2nd-ex-lambda-bucket"
}

