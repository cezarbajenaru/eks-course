module "log_metric_filter" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-metric-filter"
  version = "~> 3.0"

  log_group_name = var.log_group_name

  name    = var.metric_filtername
  pattern = var.metric_filter_pattern

  metric_transformation_namespace = var.metric_transformation_namespace
  metric_transformation_name      = var.metric_transformation_name
}