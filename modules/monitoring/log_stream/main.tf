module "log_stream" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-stream"
  version = "~> 3.0"
    
  name           = var.log_stream_name
  log_group_name = var.log_group_name
}