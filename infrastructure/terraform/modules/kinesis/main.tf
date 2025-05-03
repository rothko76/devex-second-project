# modules/kinesis/main.tf

# Security Group for Kinesis VPC endpoint
resource "aws_security_group" "kinesis_endpoint" {
  name        = "kinesis-endpoint-sg"
  description = "Allow backend to access Kinesis endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["sg-099ff5318836bf226"] #var.backend_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kinesis-endpoint-sg"
  }
}

# VPC Endpoint for Kinesis
resource "aws_vpc_endpoint" "kinesis" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.kinesis-streams"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.kinesis_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "kinesis-vpc-endpoint"
  }
}

# Kinesis Streams (loop over the stream list)
resource "aws_kinesis_stream" "this" {
  for_each = var.kinesis_streams

  name             = each.value.stream_name
#  shard_count      = each.value.shard_count
  retention_period = each.value.retention_period

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = each.value.tags
}
