terraform {
  required_version = "~>1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20.0, <7.0.0"
    }
    # Kubernetes and Helm providers removed - all K8s/Helm deployments now managed by ArgoCD
  }
}