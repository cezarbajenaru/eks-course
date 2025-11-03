variable "vpc_id" {type = string}
variable "security_group_id" {type = string}  # Fixed: was security_group_ids (plural), module expects singular

# Endpoints structure is flexible - gateway endpoints (S3, DynamoDB) don't need subnet_ids
# Interface endpoints (SNS, SQS, etc.) need subnet_ids and optional subnet_configurations
# Using 'any' type for maximum flexibility since structure varies by endpoint type
variable "endpoints" {
  type        = map(any)
  description = "Map of VPC endpoints. Gateway endpoints (S3, DynamoDB) only need service. Interface endpoints need subnet_ids."
}

variable "tags" {type = map(string)}
