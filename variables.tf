#variables will be used here in order to leave the modules as clean and reusable as possible
# VPC variables
variable "vpc_name" { type = string }
variable "vpc_cidr" { type = string }

variable "vpc_azs" { type = list(string) }
variable "vpc_private_subnets" { type = list(string) }
variable "vpc_public_subnets" { type = list(string) }

variable "vpc_enable_vpn_gateway" { type = bool }
variable "vpc_enable_nat_gateway" { type = bool }
variable "vpc_single_nat_gateway" { type = bool }
variable "vpc_reuse_nat_ips" { type = bool }
variable "vpc_external_nat_ip_ids" { type = list(string) }

variable "vpc_tags" { type = map(string) }

# Security Group variables
variable "sg_eks_project" { type = string }
variable "vpc_id" { type = string }
variable "description" { type = string }
variable "ingress_rules" { type = list(string) }
variable "ingress_with_cidr_blocks" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
    cidr_blocks = string
  }))
}

#tags
variable "tags" { type = map(string) }

# EKS variables
variable "name" {
  type        = string
  description = "Name of the EKS cluster"
}
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