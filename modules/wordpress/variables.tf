variable "namespace" {
  type        = string
  description = "Namespace where WordPress will be deployed"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name (used for ALB ingress annotations)"
}

variable "domain_name" {
  type        = string
  description = "Domain name for WordPress ingress"
}
