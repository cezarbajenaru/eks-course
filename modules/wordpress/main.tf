terraform {#this is for terraform to use the helm provider not kubernetes embeded provider
  required_providers {
    helm = {
      source  = "hashicorp/helm"
    }
    kubernetes = {# this should not be needed as it is embedded in the helm provider but just in case
      source  = "hashicorp/kubernetes"
    }
  }
}


resource "kubernetes_namespace" "wordpress" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "wordpress" {
  provider = helm
  name       = "wordpress"
  namespace  = var.namespace

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "wordpress"
  version    = "17.0.0"


  # Enable ingress
  set = [
  {
    name  = "ingress.enabled"
    value = "true"
  },
  {
    name  = "ingress.ingressClassName"
    value = "alb"
  },
  {
    name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  },
  {
    name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  },
  {
    name  = "ingress.hostname"
    value = var.domain_name
  },
  {#this is the line that connects the ALB to the S3 bucket for logs
    #ALB access logs are enabled and the bucket name is the one specified in the variables.tf file
    name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-attributes"
    value = "access_logs.s3.enabled=true,access_logs.s3.bucket=${var.alb_logs_s3_bucket}"
  },
  {
    name  = "persistence.storageClass"
    value = "gp3"
  },
  {
    name  = "persistence.size"
    value = "20Gi"
  },
  {
    name  = "service.type"
    value = "ClusterIP"
  }
]


}