module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = "my-table"
  hash_key = "id"

  attributes = [
    {
      name = "id"
      type = "N"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}