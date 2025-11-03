output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}


output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# Security Group outputs
output "security_group_id" {
  description = "The ID of the security group"
  value       = module.sg_eks_project.sg_group_id
}

output "security_group_vpc_id" {
  description = "The VPC ID of the security group"
  value       = module.sg_eks_project.vpc_id
}