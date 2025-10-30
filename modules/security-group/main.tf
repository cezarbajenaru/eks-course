module "sg-eks-project" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sg-eks-project"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = module.vpc.vpc_id  #you do not have VPC id before creation but you can automate to take it after it's creation

  ingress_cidr_blocks      = ["10.0.0.0/24"]
  ingress_rules            = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8090
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "10.0.0.0/24"
    }
  ]
}