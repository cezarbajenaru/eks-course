module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "plasticmemory-eks-cluster"
  kubernetes_version = "1.34"

#core dns and kube-proxy do not have to be created before the compute. There are not pods anyway
  addons = {
    coredns                = {} # handles DNS for the inside cluster
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {} # manages the kube-proxy service
    vpc-cni                = {
      before_compute = true
    }
  }
  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_groups = var.eks_managed_node_groups

  tags = var.tags
}