output "cluster_name" {
    value = module.eks.cluster_name
}

output "cluster_oidc_issuer_url" {
    value = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
    description = "The ARN of the OIDC provider for the EKS cluster"
    value = module.eks.oidc_provider_arn
}