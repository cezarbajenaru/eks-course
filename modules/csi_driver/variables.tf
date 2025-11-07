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

variable "addon_version" {
  description = "Version of the aws-ebs-csi-driver add-on"
  type        = string
  default     = "v1.51.1-eksbuild.1"
}