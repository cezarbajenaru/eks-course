variable "s3_alb_logs_bucket_name" {
  type = string
  description = "The name of the S3 bucket for ALB logs"
}

variable "tags" {
  type = map(string)
  description = "Tags to apply to the S3 bucket"
  default = {}
}