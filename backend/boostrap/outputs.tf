#output the state bucket name and the dynamodb lock table name
#these outputs are not mandatory but can be used for monitoring, scripts or checkups

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_id" {
  value = aws_dynamodb_table.terraform_state_lock.id
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.terraform_state_lock.arn
}