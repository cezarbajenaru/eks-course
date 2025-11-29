#https://registry.terraform.io/modules/terraform-aws-modules/cloudwatch/aws/latest/submodules/log-group#outputs

output "cloudwatch_log_group_arn" {
  value = module.log_group.cloudwatch_log_group_arn
}

output "cloudwatch_log_group_name" {
  value = module.log_group.cloudwatch_log_group_name
}