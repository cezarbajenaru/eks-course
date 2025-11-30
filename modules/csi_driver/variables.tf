variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster’s OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the cluster’s OIDC provider"
  type        = string
}

# addon_version removed - CSI driver will be deployed via ArgoCD using Helm chart
# This module now only creates the IAM role required for the CSI driver