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
    bucket         = "plastic-memory-terraform-state"
    key            = "eks/terraform.tfstate" #what does the key do? #it is the path to the state file in the S3 bucket
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}


locals {
  region = "eu-central-1"
}

provider "aws" {
  region = local.region
}

#creates a fixed EIP for the NAT Gateway and lets private subnets reach the internet through the NAT Gateway / if not, node groups do not reach internet from private subnets
#this gets created before VPC so VPC can have the EIP as input
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "eks-nat-eip"
  }
}



module "vpc" {
  source   = "./modules/vpc"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr

  vpc_azs             = var.vpc_azs
  vpc_private_subnets = var.vpc_private_subnets
  vpc_public_subnets  = var.vpc_public_subnets


  vpc_enable_nat_gateway = var.vpc_enable_nat_gateway
  vpc_single_nat_gateway = var.vpc_single_nat_gateway # because we have only one availability zone
  vpc_reuse_nat_ips      = var.vpc_reuse_nat_ips      # Skip creation of EIPs for the NAT Gateways

  vpc_external_nat_ip_ids = [aws_eip.nat.id] #aws_eip is AWS resource name, nat is the name I gave to the resource and id is the output of AWS resource


  ingress_cidr_blocks = var.ingress_cidr_blocks
  vpc_tags            = var.vpc_tags

  # Pass eks_cluster_name from tfvars (not from EKS output to avoid circular dependency)
  # VPC needs to be created before EKS, but subnet tags need cluster_name
  eks_cluster_name = var.eks_cluster_name



}

#security group module
module "sg_eks_project" {
  source              = "./modules/security_group"
  vpc_id              = module.vpc.vpc_id
  sg_eks_project      = var.sg_eks_project
  description         = var.description
  ingress_rules       = var.ingress_rules
  ingress_cidr_blocks = var.ingress_cidr_blocks
  tags                = var.tags
}

#### EKS SHOULD GO IN HERE!
module "eks" {
  source = "./modules/eks"

  eks_cluster_name   = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = var.eks_managed_node_groups
  tags                    = var.tags

}

###ALB controller install with HELM###
module "alb_irsa" {
  source            = "./modules/alb_irsa"
  cluster_name      = var.eks_cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
}

resource "helm_release" "aws_load_balancer_controller" { #called helm chart to install the ALB controller
  name      = "aws-load-balancer-controller"
  namespace = "kube-system"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.2"


  set = [
    {
      name  = "clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.alb_irsa.alb_irsa_role_arn
    },
    {
      name  = "region"
      value = "eu-central-1"
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    }
  ]
}


module "csi_driver" {
  source            = "./modules/csi_driver"
  cluster_name      = module.eks.cluster_name #csi driver is installed after EKS module exists, so we need to use the EKS cluster name which is an output of the EKS module
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
}

#mysql database creation
#KUBERNETES PROVIDERS bellow(after EKS module exists)

data "aws_eks_cluster_auth" "cluster" { #this asks AWS for a authentication token for the cluster_name
  name = module.eks.cluster_name        #cluster_name is an output of the EKS module and is used just like in CSI module
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "mysql" {
  name      = "mysql"
  namespace = "default"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  version    = "14.0.3"

  set = [
    {
      name  = "primary.persistence.storageClass"
      value = "gp3"
    },
    {
      name  = "primary.persistence.size"
      value = "20Gi"
    },
    {
      name  = "auth.rootPassword"
      value = "SuperStrongPassword123"
    }
  ]
}


module "wordpress" {
  source = "./modules/wordpress"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  namespace          = "wordpress"
  cluster_name       = module.eks.cluster_name
  domain_name        = var.wordpress_domain                   # this domain_name variable ( which is in defined in tfvars and variables.tf) is passed to the wordpress module and then used in modules/wordpress/outputs.tf
  alb_logs_s3_bucket = module.s3_bucket_for_logs.s3_bucket_id # Enable ALB access logs to S3
}

#modules/monitoring/log_group/ log group module
module "log_group" {
  source            = "./modules/monitoring/log_group"
  log_group_name    = var.log_group_name
  retention_in_days = var.retention_in_days
}


#monitoring module used DIRECTLY from the registry into root/main.tf - NO customization - does not have a modules/alarms module
#this module is wired only in root/main.tf root/variables.tf root/outputs.tf
module "cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2" #belongs where you call source from the intenet
  #bellow are the variables for the alarm, comes from terraform.tfvars in monitoring section
  namespace           = var.cpu_alarm_namespace #must be unique globally and mandatory for the alarm to work
  alarm_name          = var.cpu_alarm_name
  alarm_description   = var.cpu_alarm_description
  comparison_operator = var.cpu_comparison_operator
  metric_name         = var.cpu_metric_name
  period              = var.cpu_period             # the minutes for the metric to be collected
  evaluation_periods  = var.cpu_evaluation_periods # the minutes for threshold to be met
  threshold           = var.cpu_threshold          #triggers when over 80% CPU usage for more than 2 minutes
  statistic           = var.cpu_statistic          #uses an average value of the metric (the 80% in 2 minutes) and compares it to the threshold
  dimensions = {                                   #this has no place into root/main.tf because it is a submodule
    ClusterName = var.eks_cluster_name
  }

  #connecting the Alarm to the SNS topic happens with alarm_actions variable
  #Whenever the alarm status changes to ALARM
  #CloudWatch sends a JSON event → SNS
  #SNS forwards event to subscribed endpoints (email, etc.)
  alarm_actions = [module.sns.topic_arn]
}

module "s3_bucket_for_logs" {
  source = "./modules/monitoring/s3_logs"

  s3_alb_logs_bucket_name = var.s3_alb_logs_bucket_name #from tfvars

  tags = var.tags
}

# VPC Endpoints - Allow private subnets to access S3 and DynamoDB without NAT Gateway
# Gateway endpoints are FREE and reduce NAT Gateway data transfer costs
# Placed after S3 bucket creation so we can reference the bucket ARN
module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  vpc_id                  = module.vpc.vpc_id
  private_route_table_ids = module.vpc.private_route_table_ids

  # S3 bucket ARNs for endpoint policy (terraform state bucket + ALB logs bucket)
  s3_bucket_arns = [
    "arn:aws:s3:::plastic-memory-terraform-state",
    "arn:aws:s3:::plastic-memory-terraform-state/*",
    module.s3_bucket_for_logs.s3_bucket_arn,
    "${module.s3_bucket_for_logs.s3_bucket_arn}/*"
  ]

  tags = var.tags
}

module "sns" {
  source   = "./modules/monitoring/sns"
  sns_name = var.sns_name
  email    = var.email
  tags     = var.tags
}