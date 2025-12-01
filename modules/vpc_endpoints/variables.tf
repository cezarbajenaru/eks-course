variable "vpc_id" {
  type        = string
  description = "VPC ID where endpoints will be created"
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "List of private subnet route table IDs for gateway endpoints"
}

variable "s3_bucket_arns" {
  type        = list(string)
  description = "List of S3 bucket ARNs to allow access via VPC endpoint"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to VPC endpoints"
  default     = {}
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for interface endpoints"
}

variable "vpc_endpoint_sg_id" {
  type        = string
  description = "Security group ID for VPC endpoints (allows HTTPS from nodes)"
}