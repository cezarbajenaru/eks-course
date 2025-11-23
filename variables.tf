#variables will be used here in order to leave the modules as clean and reusable as possible
# VPC variables
variable "vpc_name" { type = string }
variable "vpc_cidr" { type = string }

variable "vpc_azs" { type = list(string) }
variable "vpc_private_subnets" { type = list(string) }
variable "vpc_public_subnets" { type = list(string) }

variable "vpc_enable_nat_gateway" { type = bool }
variable "vpc_single_nat_gateway" { type = bool }
variable "vpc_reuse_nat_ips" { type = bool }

variable "vpc_tags" { type = map(string) }

# Security Group variables
variable "sg_eks_project" { type = string }
variable "description" { type = string }
variable "ingress_rules" { type = list(string) }
variable "ingress_cidr_blocks" {
  type = list(string)
}

#tags
variable "tags" { type = map(string) }


variable "kubernetes_version" {
  type        = string
  description = "Version of the Kubernetes cluster"
}

variable "eks_managed_node_groups" { type = map(object({
  ami_type       = string
  instance_types = list(string)
  min_size       = number
  max_size       = number
  desired_size   = number
})) }

variable "eks_cluster_name" {
  type = string
  description = "Kubernetes cluster name"#it needs a cluster name to be able to create the ALB, a separate one from the EKS cluster name because EKS is not yet created when the VPC module is applied
}

variable "wordpress_domain" {
  type = string
  description = "Wordpress domain name"#used in the wordpress module to create the ingress and used in domain_name root/main.tf
}