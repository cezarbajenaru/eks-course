terraform {#this is for terraform to use the helm provider not kubernetes embeded provider
  required_providers {
    helm = {
      source  = "hashicorp/helm"
    }
    kubernetes = {
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