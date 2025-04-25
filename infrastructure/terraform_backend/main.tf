provider "aws" {
  region = "us-east-1"  # Change to your AWS region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_bucket_name  # Change to your S3 bucket name
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

resource "aws_dynamodb_table" "terraform_lock_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  # The hash_key is used as the primary key for DynamoDB to manage Terraform state locking.
  # "LockID" is chosen because it uniquely identifies the lock for a specific Terraform state.
  # This ensures that concurrent operations on the same state file are prevented, maintaining consistency.
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"  # "S" indicates that the attribute type is a string in DynamoDB
  }
}
