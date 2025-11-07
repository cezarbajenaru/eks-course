output "security_group_owner_id" {
    value = module.sg_eks_project.security_group_owner_id# we can use this to identify the owner of the SG
}

output "security_group_id" {
    value = module.sg_eks_project.security_group_id
}

output "security_group_arn" {
    value = module.sg_eks_project.security_group_arn
}

output "security_group_vpc_id" {
    value = module.sg_eks_project.security_group_vpc_id
}

output "security_group_name" {
    value = module.sg_eks_project.security_group_name
}


