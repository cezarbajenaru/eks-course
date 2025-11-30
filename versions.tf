terraform {
  required_version = "~>1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20.0, <7.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }
}