module "s3_bucket_state" {
  source = "terraform-aws-modules/s3-bucket/aws"

bucket = "s3-bucket-state-eks-project-${local.region}"
  force_destroy = true
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
}