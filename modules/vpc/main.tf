module "vpc" {  #  this module downloads terraform vpc module from the registry and creates a vpc with the given parameters
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_vpn_gateway  = var.vpc_enable_vpn_gateway
  enable_nat_gateway  = var.vpc_enable_nat_gateway
  single_nat_gateway  = var.vpc_single_nat_gateway # because we have only one availability zone in this project
  reuse_nat_ips       = var.vpc_reuse_nat_ips                   # Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = var.vpc_external_nat_ip_ids       # IPs specified here as input to the module

  tags = var.vpc_tags
}