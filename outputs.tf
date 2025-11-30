#modules/vpc/ VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}


output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}


#backend/boostrap/ bootstrap outputs for dynamodb table
# There are not outputs for the bootstrap module because it is not a module, it is a resource.


#modules/eks/ EKS outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_name" {
  description = "Name of the EKS cluster (alias for eks_cluster_name)"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}





#modules/security_group/ Security Group outputs
output "security_group_name" {
  description = "The ID of the security group"
  value       = module.sg_eks_project.security_group_name
}

output "security_group_vpc_id" {
  description = "The VPC ID of the security group"
  value       = module.sg_eks_project.security_group_vpc_id
}

#modules/monitoring/log_group/ log group module outputs
output "cloudwatch_log_group_arn" {
  value = module.log_group.cloudwatch_log_group_arn
}

output "cloudwatch_log_group_name" {
  value = module.log_group.cloudwatch_log_group_name
}


#modules/monitoring/alarms/ alamrs module outputs
output "cpu_alarm_arn" {
  value = module.cpu_alarm.cloudwatch_metric_alarm_arn
}

output "cpu_alarm_id" {
  value = module.cpu_alarm.cloudwatch_metric_alarm_id
}


#modules/monitoring/s3_logs/ ALB S3 logs module outputs
output "s3_bucket_id" {
  value = module.s3_bucket_for_logs.s3_bucket_id
}

output "s3_bucket_arn" {
  value = module.s3_bucket_for_logs.s3_bucket_arn
}


#modules/monitoring/sns/ SNS module outputs
output "topic_arn" {
  value = module.sns.topic_arn
}

# IAM Role ARNs for ArgoCD deployments
output "alb_irsa_role_arn" {
  description = "IAM role ARN for ALB Controller (for ArgoCD Helm chart)"
  value       = module.alb_irsa.alb_irsa_role_arn
}

output "csi_driver_role_arn" {
  description = "IAM role ARN for EBS CSI Driver (for ArgoCD Helm chart)"
  value       = module.csi_driver_irsa.csi_driver_role_arn
}