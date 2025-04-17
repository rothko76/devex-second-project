##backend
terraform {
  backend "s3" {
    bucket         = "devex-2nd-ex-terraform-state-bucket"
    key            = "prod/terraform.tfstate"  # Path inside the bucket
    region         = "us-east-1"
    encrypt        = true                      # Encrypt the state file
    dynamodb_table = "devex-2nd-ex-terraform-lock-table"       # For state locking
  }
}


#Vpc
module "vpc" {
  source = "./modules/vpc"

  name              = "aws-vpc"
  cidr              = "10.0.0.0/16"
  azs               = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets    = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "aws-vpc"
  }
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
}


# EKS Cluster to host the backend application
# module "eks" {
#   source = "./modules/eks"

#   cluster_name    = var.cluster_name
#   cluster_version = "1.28"
#   subnet_ids      = module.vpc.private_subnets
#   vpc_id          = module.vpc.vpc_id

#   eks_managed_node_groups = {
#     eks_nodes = {
#       desired_capacity = var.desired_capacity
#       max_size         = var.max_size
#       min_size         = var.min_size

#       instance_types = ["t3.medium"]

#       labels = {
#         Environment = "dev"
#       }
#     }
#   }

#   cluster_endpoint_public_access = true

#   tags = {
#     Name = "eks-cluster"
#   }
# }

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "custom-db-subnet-group"
 # subnet_ids = module.vpc.private_subnets
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "custom-db-subnet-group"
  }
}

# RDS PostgreSQL
module "rds_postgres" {
  source = "./modules/rds-postgres"

  allocated_storage    = 20
  engine_version       = "13"
  instance_class       = "db.t3.micro"
  db_name              = "devex_second_project"
  username             = "postgres_user"
  password             = "password1234"
  publicly_accessible  = true
  vpc_security_group_ids = [module.security_groups.rds_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  parameter_group_name   = "default.postgres13"
  skip_final_snapshot    = true

  tags = {
    Name = "flask-app-rds"
  }
}


##Kinesis module
module "kinesis" {
  source = "./modules/kinesis"

  vpc_id         = module.vpc.vpc_id
  region         = var.region
  backend_sg_ids = [module.security_groups.kinesis_sg_id]  # Example, replace with your SG
  subnet_ids = module.vpc.private_subnets

  
  kinesis_streams = {
    user_stream = {
      stream_name       = "user"
      retention_period  = 24
      tags = {
        Name = "user"
        Environment = "dev"
      }
    },
    product_stream = {
      stream_name        = "product"
      retention_period  = 24
      tags= {
        Name = "product"
        Environment = "dev"
      }
    },
    order_stream = {
      stream_name        = "order"
      retention_period  = 24
      tags= {
        Name = "order"
        Environment = "dev"
      }
    }
  }
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "my-lambda-function"
  s3_bucket     = "devex-2nd-ex-lambda-bucket"
  s3_key        = "lambda_function.zip"

#  image_uri = "577640772961.dkr.ecr.us-east-1.amazonaws.com/devex-2nd-ex-lambda-repo:latest"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  role    = "arn:aws:iam::577640772961:role/lambda-kinesis-role"
#  package_type  = "Image"
#  timeout       = 30
#  memory_size   = 512

  layers = [
      "arn:aws:lambda:us-east-1:577640772961:layer:psycopg2_binary:1"
    ]

  source_code_hash = data.aws_s3_object.lambda_object.etag

    environment {
    variables = {
      DB_HOST     = module.rds_postgres.rds_hostname

      #DB_HOST     = "_terraform-20250417072738679900000006.cwnw2e6a4074.us-east-1.rds.amazonaws.com" #module.rds_postgres.rds_hostname
  #     #DB_PORT     = module.rds_postgres.rds_port
      DB_USER     = "postgres_user"#module.rds_postgres.username
      DB_PASSWORD = "password1234" #module.rds_postgres.password
      DB_NAME     = "devex_second_project"#module.rds_postgres.db_name
  #     # Other variables...
    }
  }
}

data "aws_s3_object" "lambda_object" {
  bucket = "devex-2nd-ex-lambda-bucket"
  key    = "lambda_function.zip"
}


resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = "arn:aws:kinesis:us-east-1:577640772961:stream/order"
  function_name     = aws_lambda_function.my_lambda.arn
  starting_position = "LATEST"
  batch_size        = 1

  # Optional settings:
  enabled           = true
}