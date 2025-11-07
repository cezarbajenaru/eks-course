module "sg_eks_project" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.sg_eks_project
  description = var.description
  vpc_id      = var.vpc_id  # VPC ID is passed from root module as a variable

  ingress_cidr_blocks      = var.ingress_cidr_blocks
  ingress_rules            = var.ingress_rules
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
  tags = var.tags
}