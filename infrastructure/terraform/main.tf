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