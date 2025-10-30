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
  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_vpn_gateway  = var.vpc_enable_vpn_gateway
  enable_nat_gateway  = var.vpc_enable_nat_gateway
  single_nat_gateway  = var.vpc_single_nat_gateway # because we have only one availability zone
  reuse_nat_ips       = var.vpc_reuse_nat_ips                   # Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = var.vpc_external_nat_ip_ids       # IPs specified here as input to the module

  tags = var.vpc_tags
}
  
# Allocate EIPs for NAT Gateways
#resource "aws_eip" "nat" {
#  count = var.vpc_single_nat_gateway ? 1 : length(var.vpc_azs) # Allocate only one EIP if single_nat_gateway is true - code translation: condition ? result_if_true : result_if_false
#}
