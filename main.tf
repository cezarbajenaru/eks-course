#module "<logical_name>" {
#  source  = "<registry_path>"
#  version = "<module_version>"
#
#  # input variables expected by the module
#  variable1 = "value"
#  variable2 = "value"
#}


#terraform state backend configuration - where state will be stored
terraform {
    backend "s3" {
      bucket = "plastic-memory-terraform-state"
      key = "eks/terraform.tfstate"
      region = "eu-central-1"
      dynamodb_table = "terraform-state-lock"
      encrypt = true
   }
}

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

#security group module
module "sg_eks_project" {
  source = "./modules/security_group"
  vpc_id = module.vpc.vpc_id
  sg_eks_project = var.sg_eks_project
  description = var.description
  ingress_rules = var.ingress_rules
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
  tags = var.tags
}

#### EKS SHOULD GO IN HERE!
module "eks" {
  source = "./modules/eks"
  
  name = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = var.eks_managed_node_groups
  tags = var.tags
}

module "csi_driver" {
  source            = "./modules/csi_driver"
  cluster_name = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
}

#mysql database creation


data "aws_eks_cluster_auth" "cluster" {#this asks AWS for a authentication token for the cluster_name
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "mysql" {#this is a helm release for the mysql chart
  name       = "mysql"
  namespace  = "default"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  version    = ">= 9.0.0"
  
  set {
    name  = "primary.persistence.storageClass"
    value = "gp3"
  }

  set {
    name  = "primary.persistence.size"
    value = "20Gi"
  }

  set {
    name  = "auth.rootPassword"
    value = "SuperStrongPassword123" # change before sharing
  }
}