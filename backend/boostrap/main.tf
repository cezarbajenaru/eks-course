#This module will have to run first so we can use the state of the infrastructure in the root/main.tf
provider "aws" {
    region = "eu-central-1"
}


resource "aws_s3_bucket" "terraform_state" {
    bucket = "plastic-memory-terraform-state"

    versioning {
        enabled = true
    }
    lifecycle {
        prevent_destroy = true
    }

    resource "aws_dynamodb_table" "terraform_state_lock" {
        name = "terraform-state-lock"
        billing_mode = "PAY_PER_REQUEST"
        hash_key = "LockID"
        attribute {
            name = "LockID"
            type = "S"
        }
    }

}