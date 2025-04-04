variable "name" {
  description = "The name of the Kinesis stream"
  type        = string
}

variable "shard_count" {
  description = "The number of shards for the stream"
  type        = number
}

variable "retention_period" {
  description = "The retention period for the stream (in hours)"
  type        = number
}

variable "tags" {
  description = "Tags for the Kinesis stream"
  type        = map(string)
}