# here we are declaring which AWS services we want to access with our private subnets - no internet
#Each key (s3, dynamodb, sqs, etc.) corresponds to one AWS service endpoint.
#You can include or remove any of them — there’s no requirement to have all.

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = "vpc-12345678" #module.vpc.vpc_id
  security_group_ids = ["sg-12345678"]#module.sg_eks_project.security_group_id

  endpoints = {
    s3 = {
      # interface endpoint
      service             = "s3"
      tags                = { Name = "s3-vpc-endpoint" }
    },
    sns = {
      service               = "sns"
      subnet_ids            = ["subnet-12345678", "subnet-87654321"]
      subnet_configurations = [
        {
          ipv4      = "10.8.34.10"
          subnet_id = "subnet-12345678"
        },
        {
          ipv4      = "10.8.35.10"
          subnet_id = "subnet-87654321"
        }
      ]
      tags = { Name = "sns-vpc-endpoint" }
    },
  }

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}