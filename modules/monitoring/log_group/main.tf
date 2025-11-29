module "log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = var.log_group_name
  retention_in_days = var.retention_in_days
}