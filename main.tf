#module "<logical_name>" {
#  source  = "<registry_path>"
#  version = "<module_version>"
#
#  # input variables expected by the module
#  variable1 = "value"
#  variable2 = "value"
#}

locals {
  region = "eu-central-1"
}

provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
source = "./modules/vpc"
  vpc_name                = var.vpc_name
  vpc_cidr                = var.vpc_cidr

  vpc_azs                 = var.vpc_azs
  vpc_private_subnets     = var.vpc_private_subnets
  vpc_public_subnets      = var.vpc_public_subnets

  vpc_enable_vpn_gateway  = var.vpc_enable_vpn_gateway
  vpc_enable_nat_gateway  = var.vpc_enable_nat_gateway
  vpc_single_nat_gateway  = var.vpc_single_nat_gateway # because we have only one availability zone
  vpc_reuse_nat_ips       = var.vpc_reuse_nat_ips                   # Skip creation of EIPs for the NAT Gateways
  #vpc_external_nat_ip_ids = aws_eip.nat[*].id       # IPs specified here as input to the module

  vpc_tags                = var.vpc_tags
}


module "sg_eks_project" {
  source = "./modules/security-group"
  sg_eks_project = var.sg_eks_project
  description = var.description
  vpc_id = module.vpc.vpc_id
  ingress_cidr_blocks = var.ingress_cidr_blocks
  ingress_rules = var.ingress_rules
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
  tags = var.tags
}