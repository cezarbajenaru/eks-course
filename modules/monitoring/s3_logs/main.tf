# Here we have a storage for ALB logs
module "s3_bucket_for_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "5.9.0" #this has no place into root/main.tf 
  
  bucket = var.s3_alb_logs_bucket_name #from tfvars

  # Allow deletion of non-empty bucket
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

#These two lines tie the ALB to the S3 bucket / they are needed for ALB services to write logs to the bucket
  attach_elb_log_delivery_policy = true
  attach_lb_log_delivery_policy  = true
}