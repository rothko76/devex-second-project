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


#EKS Cluster to host the backend application
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    eks_nodes = {
      desired_capacity = var.desired_capacity
      max_size         = var.max_size
      min_size         = var.min_size
#      security_groups = [aws_security_group.kinesis_endpoint_sg_allow_eks.id]  # Use your SG here
      instance_types = ["t3.medium"]

      labels = {
        Environment = "dev"
      }
    }
  }

  cluster_endpoint_public_access = true

  tags = {
    Name = "eks-cluster"
  }
}

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
    product_stream = {
      stream_name        = "product"
      retention_period  = 24
      tags= {
        Name = "product"
        Environment = "dev"
      }
    }
  }
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "my-lambda-function"
  s3_bucket     = "devex-2nd-ex-lambda-bucket"
  s3_key        = "lambda_function.zip"

  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  role    = "arn:aws:iam::577640772961:role/lambda-kinesis-role"

  layers = [
      "arn:aws:lambda:us-east-1:577640772961:layer:psycopg2_binary:1"
    ]

  source_code_hash = data.aws_s3_object.lambda_object.etag

    environment {
    variables = {
      DB_HOST     = module.rds_postgres.rds_hostname
      DB_USER     = "postgres_user"#module.rds_postgres.username
      DB_PASSWORD = "password1234" #module.rds_postgres.password
      DB_NAME     = "devex_second_project"#module.rds_postgres.db_name
    }
  }
}

data "aws_s3_object" "lambda_object" {
  bucket = "devex-2nd-ex-lambda-bucket"
  key    = "lambda_function.zip"
}


resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = "arn:aws:kinesis:us-east-1:577640772961:stream/product"
  function_name     = aws_lambda_function.my_lambda.arn
  starting_position = "LATEST"
  batch_size        = 1

  # Optional settings:
  enabled           = true
}


# Bastion Host stuff
resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = file("bastion-key.pub")
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from my IP to Bastion Host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["109.67.155.79/32"] #My IP address for enhanced security
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }

}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# resource "aws_iam_role" "eks_access_role" {
#   name = "eks-access-role"

#   assume_role_policy = `jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       "Action": [
#           "eks:DescribeCluster",
#           "eks:ListClusters"
#         ]    
#         }
#     ]
#   })

#   tags = {
#     Name = "eks-access-role"
#   }
# }

# resource "aws_iam_role_policy_attachment" "eks_access_policy_attachment" {
#   role       = aws_iam_role.eks_access_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_instance_profile" "eks_access_instance_profile" {
#   name = "eks-access-instance-profile"
#   role = aws_iam_role.eks_access_role.name
# }

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"  # cheap and enough for SSH
  subnet_id                   = module.vpc.public_subnets[0] # Use the first public subnet
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion_key.key_name
  #iam_instance_profile        = aws_iam_instance_profile.eks_access_instance_profile.name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y unzip wget curl jq bash-completion git
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/latest/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mv ./kubectl /usr/local/bin/
    echo "source <(kubectl completion bash)" >> /etc/bashrc
    echo "alias k=kubectl" >> /etc/bashrc
    echo "complete -F __start_kubectl k" >> /etc/bashrc
    curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
    mv /tmp/eksctl /usr/local/bin
  EOF

  tags = {
    Name = "bastion-host"
  }
}


# resource "aws_security_group" "kinesis_endpoint_sg_allow_eks" {
#   name        = "kinesis-vpc-endpoint-sg"
#   description = "Allow EKS nodes to access Kinesis VPC endpoint"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "Allow HTTPS from EKS nodes"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     security_groups = [module.eks.node_security_group_id]  # Use the EKS node security group
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "kinesis-endpoint-sg-allow-eks"
#   }
# }

# resource "aws_vpc_endpoint" "kinesis" {
#   vpc_id              = module.vpc.vpc_id
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.kinesis_endpoint_sg_allow_eks.id]
#   service_name        = "com.amazonaws.${var.region}.kinesis-streams"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true

#   tags = {
#     Name = "kinesis-vpc-endpoint"
#   }
# }
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "kinesis_write_policy_attachment" {
  role       = "eks_nodes-eks-node-group-20250503064836807400000001"  # Replace with the actual worker node IAM role name
  policy_arn = aws_iam_policy.kinesis_write_policy.arn
}

resource "aws_iam_policy" "kinesis_write_policy" {
  name        = "KinesisWritePolicy"
  description = "IAM policy to allow EKS worker nodes to access Kinesis"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListStreams",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ],
        Resource = "arn:aws:kinesis:us-east-1:${data.aws_caller_identity.current.account_id}:stream/*"
      }
    ]
  })
}

output "kinesis_write_policy_arn" {
  value = aws_iam_policy.kinesis_write_policy.arn
}

