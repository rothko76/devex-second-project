provider "aws" {
  region = "us-east-1"  # Change to your AWS region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "devex-2nd-ex-terraform-state-bucket"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "devex-2nd-ex-terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  # The hash_key is used as the primary key for DynamoDB to manage Terraform state locking.
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
