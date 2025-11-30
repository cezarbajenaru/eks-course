# ArgoCD Migration Guide

## What to Remove from Terraform

### 1. Remove Application Deployments

**From `main.tf`:**
- Remove `resource "helm_release" "mysql"` (lines 174-204)
- Remove `module "wordpress"` (lines 207-225)
- Remove Kubernetes/Helm providers if only used for apps (lines 156-172)

**Files to Delete:**
- `modules/wordpress/` (entire directory)

### 2. Optional: Keep Providers for ALB Controller

If you keep ALB controller in Terraform, keep the providers.
If you move ALB controller to ArgoCD, remove providers.

## What to Keep in Terraform

✅ **Infrastructure (Keep):**
- VPC module
- EKS cluster and node groups
- Security groups
- ALB IRSA module
- CSI driver (EKS addon)
- ALB controller (recommended to keep)
- S3 buckets
- VPC endpoints
- CloudWatch log groups
- SNS topics
- CloudWatch alarms

## ArgoCD Application Structure

After removing from Terraform, create ArgoCD applications:

### MySQL Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mysql
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: mysql
    targetRevision: 14.0.3
    helm:
      values: |
        primary:
          persistence:
            storageClass: gp3
            size: 20Gi
        auth:
          rootPassword: <use-secret>
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### WordPress Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wordpress
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: wordpress
    targetRevision: 17.0.0
    helm:
      values: |
        ingress:
          enabled: true
          ingressClassName: alb
          annotations:
            alb.ingress.kubernetes.io/scheme: internet-facing
            alb.ingress.kubernetes.io/target-type: ip
            alb.ingress.kubernetes.io/load-balancer-attributes: access_logs.s3.enabled=true,access_logs.s3.bucket=<S3_BUCKET_ID>
          hostname: <your-domain>
        persistence:
          storageClass: gp3
          size: 20Gi
        service:
          type: ClusterIP
  destination:
    server: https://kubernetes.default.svc
    namespace: wordpress
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Migration Steps

1. **Remove from Terraform:**
   ```bash
   # Comment out or remove MySQL and WordPress resources
   # Then run:
   terraform plan  # Review what will be destroyed
   terraform apply # Remove from Terraform state
   ```

2. **Create ArgoCD Applications:**
   - Apply the ArgoCD Application manifests above
   - ArgoCD will deploy MySQL and WordPress

3. **Verify:**
   ```bash
   kubectl get applications -n argocd
   argocd app get mysql
   argocd app get wordpress
   ```

## Benefits

- ✅ Applications managed via GitOps
- ✅ Faster application deployments
- ✅ Better separation: Infrastructure (Terraform) vs Apps (ArgoCD)
- ✅ ArgoCD handles dependencies automatically
- ✅ Easy rollbacks and sync status visibility

