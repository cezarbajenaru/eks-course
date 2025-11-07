variable "vpc_id" { type = string } 
variable "sg_eks_project" { type = string }
variable "description" { type = string }
variable "ingress_rules" {type = list(string)}
variable "ingress_with_cidr_blocks" {type = list(object({
    from_port = number
    to_port = number
    protocol = string
    description = string
    cidr_blocks = string # terraform-aws-modules expects string, not list
}))}


variable "tags" { type = map(string) }