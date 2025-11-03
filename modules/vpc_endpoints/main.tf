# here we are declaring which AWS services we want to access with our private subnets - no internet
#Each key (s3, dynamodb, sqs, etc.) corresponds to one AWS service endpoint.
#You can include or remove any of them — there’s no requirement to have all.

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = var.vpc_id
  security_group_id = var.security_group_id

  endpoints = {# the endpoints are intended for all two S3 buckets. It is a general declaration
    s3 = {
      service = "s3"
      service_type = "Gateway"
      route_table_ids = [var.route_table_id] # ???????
      policy = data.aws_iam_policy_document.s3.json
      tags = { Name = "s3-vpc-endpoint" }
    }
    dynamodb = {
      service = "dynamodb"
      service_type = "Gateway"
      route_table_ids = [var.route_table_id] # ???????
      tags = { Name = "dynamodb-vpc-endpoint" }
    }
  }
  
  
  
  tags = var.tags
}