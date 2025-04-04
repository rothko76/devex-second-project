variable "allocated_storage" {
  description = "The size of the database (in GB)"
  type        = number
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
}

variable "instance_class" {
  description = "The instance class for the database"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "username" {
  description = "The master username for the database"
  type        = string
  default = "postgres_user"
}

variable "password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

variable "parameter_group_name" {
  description = "The parameter group for the database"
  type        = string
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
}

variable "vpc_security_group_ids" {
  description = "The security groups for the database"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "The subnet group for the database"
  type        = string
}

variable "tags" {
  description = "Tags for the database"
  type        = map(string)
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot before deleting the database"
  type        = bool
  default     = true
}
