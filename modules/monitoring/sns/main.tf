#https://registry.terraform.io/modules/terraform-aws-modules/sns/aws/latest

module "sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.0.0"

  name = var.sns_name

  subscriptions = {
    email = {
      protocol = "email"#this can remain hardcoded here because it is the only protocol supported by the SNS module
      endpoint = var.email #from tfvars
    }
  }
  tags = var.tags
}