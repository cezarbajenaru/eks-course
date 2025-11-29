module "vpc" {  #  this module downloads terraform vpc module from the registry and creates a vpc with the given parameters
  source = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway  = var.vpc_enable_nat_gateway
  single_nat_gateway  = var.vpc_single_nat_gateway # because we have only one availability zone in this project
  reuse_nat_ips       = var.vpc_reuse_nat_ips                   # Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = var.vpc_external_nat_ip_ids       # IPs specified here as input to the module

#used for ALB to be able to find the subnets - find them in variables.tf(where the inputs are defined)
#subnets tags just like AWS wants them to be named with the correct naming convention and values
#subnet tags must exist before the EKS cluster main resources get used  
#Later when ALB runs it will use these tags to find the subnets and create the ALB
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared" #cluster name is passed from main.tf to avoid circular dependency
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
  
#Global VPC tags
  tags = var.vpc_tags

}



