output "vpc_endpoints" {
  description = "Map of VPC endpoints created"
  value = module.vpc_endpoints.endpoints
}

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value = module.vpc_endpoints.security_group_arn
}

output "security_group_id" {
  description = "ID of the security group"
  value = module.vpc_endpoints.security_group_id
}