# Create an SSH key pair
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")  # Path to your public key
}

# Security Group for EC2 and RDS
resource "aws_security_group" "flask_app_sg" {
  name        = "flask-app-sg"
  description = "Allow access to EC2 and RDS"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  default     = "ami-084568db4383264d4"  # Ubuntu 20.04 LTS
}

# EC2 Instance with Docker and IAM Profile for S3 and ECR Access
resource "aws_instance" "flask_app_ec2" {
  ami                         = var.ami_id
  instance_type               = var.testing_instance_type
  key_name                    = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.flask_app_sg.id]
  #iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile_new.name

  # Install Docker and Start Container
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y docker.io
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "flask-app-ec2"
  }
}

# output "flask_app_url" {
#   value       = "http://${aws_instance.flask_app.public_ip}"
#   description = "URL to access the Flask application"
# }