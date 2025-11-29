# taken from https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=outputs

output "cluster_name" {
    description = "Name of the EKS cluster"
    value = module.eks.cluster_name
}

output "cluster_endpoint" {
    description = "Endpoint for EKS control plane"
    value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
    description = "Base64 encoded certificate data required to communicate with the cluster"
    value = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
    value = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
    description = "The ARN of the OIDC provider for the EKS cluster"
    value = module.eks.oidc_provider_arn
}