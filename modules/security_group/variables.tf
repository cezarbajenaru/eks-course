variable "vpc_id" { type = string } 
variable "sg_eks_project" { type = string }
variable "description" { type = string }
variable "ingress_rules" {type = list(string)}
variable "ingress_cidr_blocks" {type = list(string)}


variable "tags" { type = map(string) }