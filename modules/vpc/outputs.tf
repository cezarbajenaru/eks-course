output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "private_route_table_ids" {
  description = "List of private subnet route table IDs (needed for VPC endpoints)"
  value       = module.vpc.private_route_table_ids
}