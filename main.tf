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
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway  = var.vpc_enable_nat_gateway
  single_nat_gateway  = var.vpc_single_nat_gateway
  reuse_nat_ips       = var.vpc_reuse_nat_ips
  external_nat_ip_ids = [aws_eip.nat.id]

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet tags for ALB Controller to find subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  tags = var.vpc_tags
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

# Security group for VPC endpoints (ECR interface endpoints)
# Allows HTTPS traffic from EKS nodes to VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.eks_cluster_name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints - allows HTTPS from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTPS from EKS nodes"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.eks_cluster_name}-vpc-endpoints-sg"
  })
}

### IAM Roles for Service Accounts (IRSA) - Required for ALB Controller and CSI Driver ###
# These IAM roles are AWS infrastructure and must remain in Terraform
# The actual Helm deployments (ALB Controller, CSI Driver) will be managed by ArgoCD

module "alb_irsa" {
  source            = "./modules/alb_irsa"
  cluster_name      = var.eks_cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
}

module "csi_driver_irsa" {
  source            = "./modules/csi_driver"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
}

# Output IAM role ARNs for ArgoCD to use in Helm chart values
# ArgoCD will deploy ALB Controller and CSI Driver using these IAM roles

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
  private_subnet_ids      = module.vpc.private_subnets
  vpc_endpoint_sg_id      = aws_security_group.vpc_endpoints.id

  # S3 bucket ARNs for endpoint policy (terraform state bucket + ALB logs bucket)
  # Note: S3 endpoint policy is set to null to allow ECR image layer access
  s3_bucket_arns = []

  tags = var.tags
}

module "sns" {
  source   = "./modules/monitoring/sns"
  sns_name = var.sns_name
  email    = var.email
  tags     = var.tags
}