# modules/kinesis/variables.tf

variable "vpc_id" {
  description = "VPC ID where resources are deployed"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the VPC endpoint"
  type        = list(string)
}

variable "backend_sg_ids" {
  description = "Security group IDs for backend resources"
  type        = list(string)
}

# Define a list of streams to be created
variable "kinesis_streams" {
  description = "List of Kinesis streams to create"
  type = map(object({
    stream_name      = string
 #   shard_count      = number
    retention_period = number
    tags             = map(string)
  }))
}


