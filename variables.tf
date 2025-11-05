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
variable "description" { type = string }
variable "ingress_cidr_blocks" { type = list(string) }
variable "ingress_rules" { type = list(string) }
variable "ingress_with_cidr_blocks" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
    cidr_blocks = list(string)
  }))
}


## VPC Endpoints variables
variable "vpc_id" {type = string}
variable "security_group_ids" {type = list(string)}
variable "endpoints" {type = map(object({service = string, subnet_ids = list(string), subnet_configurations = list(object({ipv4 = string, subnet_id = string}))}))}


#tags
variable "tags" { type = map(string) }

# EKS variables
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}
variable "kubernetes_version" {
  type        = string
  description = "Version of the Kubernetes cluster"
}