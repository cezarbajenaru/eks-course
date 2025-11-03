output "vpc_id" {
  value = module.sg_eks_project.security_group_vpc_id
}

output "owner_id" {
    value = module.sg_eks_project.security_group_owner_id# we can use this to identify the owner of the SG
}

output "sg_group_id" {
    value = module.sg_eks_project.security_group_id
}