variable "s3_bucket_name" {
  description = "The name of the S3 bucket for Terraform state storage"
  type        = string
  default     = "devex-2nd-ex-terraform-state-bucket"  # Default name for the S3 bucket
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use for the S3 bucket"
  type        = string
  default     = "AES256"  # Default to AES256 encryption
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "devex-2nd-ex-terraform-lock-table"  # Default name for the DynamoDB table
}