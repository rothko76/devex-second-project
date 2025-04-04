resource "aws_db_instance" "rds-postgres" {
  allocated_storage    = var.allocated_storage
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_name              = var.db_name
  username             = var.username
  password             = var.password
  parameter_group_name = var.parameter_group_name
  publicly_accessible  = var.publicly_accessible
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name = var.db_subnet_group_name
  skip_final_snapshot  = var.skip_final_snapshot
  tags                 = var.tags
}

# Use a null_resource to run the SQL after the DB is created
resource "null_resource" "db_setup" {
  depends_on = [aws_db_instance.rds-postgres]

  provisioner "local-exec" {
    command = "PGPASSWORD='${var.password}' psql -h ${aws_db_instance.rds-postgres.address} -U ${var.username} -d ${var.db_name} -f ${path.module}/db_schema.sql"
  }
}