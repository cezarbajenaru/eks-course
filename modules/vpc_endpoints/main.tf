# VPC Endpoints allow private subnets to access AWS services (S3, DynamoDB) without going through NAT Gateway
# Gateway endpoints (S3, DynamoDB) are FREE and save NAT Gateway data transfer costs
# This is especially useful for accessing S3 buckets (terraform state, ALB logs) from private subnets
# Gateway endpoints work at the route table level - traffic is automatically routed through the endpoint

# VPC endpoint policy for S3 - restricts access to specific buckets (optional, for security)
data "aws_iam_policy_document" "s3_endpoint_policy" {
  count = length(var.s3_bucket_arns) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = var.s3_bucket_arns
  }
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = var.vpc_id
  # Gateway endpoints (S3, DynamoDB) don't need security_group_id
  # Only interface endpoints need security groups

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = var.private_route_table_ids # All private subnet route tables
      # Policy set to null to allow ECR image layer access (prod-*-starport-layer-bucket)
      # Nodes need access to ECR's S3 buckets for image pulls
      policy = null
      tags   = { Name = "s3-vpc-endpoint" }
    }
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = var.private_route_table_ids # All private subnet route tables
      # DynamoDB endpoint doesn't need a policy for basic access
      tags = { Name = "dynamodb-vpc-endpoint" }
    }
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = var.private_subnet_ids
      security_group_ids  = [var.vpc_endpoint_sg_id]
      tags                = { Name = "ecr-api-vpc-endpoint" }
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = var.private_subnet_ids
      security_group_ids  = [var.vpc_endpoint_sg_id]
      tags                = { Name = "ecr-dkr-vpc-endpoint" }
    }
  }

  tags = var.tags
}
