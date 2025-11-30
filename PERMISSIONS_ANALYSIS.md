# Permissions and Roles Analysis

## ✅ What's Properly Configured

### 1. **AWS IAM Roles for Service Accounts (IRSA)**

#### ALB Controller IRSA ✅
- **Location**: `modules/alb_irsa/main.tf`
- **Role Name**: `{cluster_name}-alb-irsa`
- **Policy**: Uses proper ALB controller IAM policy from `iam_policy.json`
- **Trust Policy**: Correctly configured to trust OIDC provider
- **Service Account**: `system:serviceaccount:kube-system:aws-load-balancer-controller`
- **Status**: ✅ Properly configured

#### EBS CSI Driver IRSA ✅
- **Location**: `modules/csi_driver/main.tf`
- **Role Name**: `AmazonEKS_EBS_CSI_DriverRole`
- **Policy**: Uses AWS managed policy `AmazonEBSCSIDriverPolicy`
- **Trust Policy**: Correctly configured to trust OIDC provider
- **Service Account**: `system:serviceaccount:kube-system:ebs-csi-controller-sa`
- **Status**: ✅ Properly configured

### 2. **EKS Cluster Permissions**
- **Cluster Creator Admin**: Enabled (`enable_cluster_creator_admin_permissions = true`)
- **OIDC Provider**: Automatically created by EKS module
- **Status**: ✅ Properly configured

### 3. **VPC Endpoints**
- **S3 Gateway Endpoint**: FREE, properly configured
- **DynamoDB Gateway Endpoint**: FREE, properly configured
- **Policy**: Restricts S3 access to specific buckets (good security practice)
- **Status**: ✅ Properly configured

### 4. **S3 Bucket Permissions**
- **ALB Logs Bucket**: Has ELB log delivery policy attached
- **Status**: ✅ Properly configured

## ⚠️ Issues Found

### 1. **Missing Service Account for ALB Controller** ⚠️ CRITICAL

**Problem**: The Helm chart is configured with `serviceAccount.create = false`, but the service account is not created elsewhere.

**Location**: `main.tf` line 121-122
```terraform
{
  name  = "serviceAccount.create"
  value = "false"
}
```

**Impact**: The ALB controller will fail to start because:
1. The service account doesn't exist
2. The IRSA role annotation won't be applied
3. The controller won't have AWS permissions

**Solution Options**:

**Option A**: Let Helm create it (Recommended)
```terraform
{
  name  = "serviceAccount.create"
  value = "true"  # Change to true
}
```

**Option B**: Create it manually with Kubernetes provider
```terraform
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.alb_irsa.alb_irsa_role_arn
    }
  }
}
```

### 2. **Terraform User Permissions** ⚠️ NEEDS VERIFICATION

**Current User**: `arn:aws:iam::398879776142:user/cezar`

**Required Permissions for Terraform Apply**:

The user needs permissions to create:
- VPC, Subnets, Route Tables, Internet Gateway, NAT Gateway
- EKS Cluster and Node Groups
- IAM Roles and Policies
- Security Groups
- S3 Buckets
- CloudWatch Log Groups
- SNS Topics
- EBS Volumes (via CSI driver)
- Elastic IPs
- VPC Endpoints
- DynamoDB Tables (for state locking)

**Recommended IAM Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "iam:*",
        "s3:*",
        "logs:*",
        "sns:*",
        "dynamodb:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudformation:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Or use**: `PowerUserAccess` managed policy (less secure but simpler)

**Action Required**: Verify your IAM user has sufficient permissions before running `terraform apply`.

### 3. **Kubernetes RBAC** ⚠️ PARTIALLY CONFIGURED

**Current State**:
- EKS module creates default RBAC
- Cluster creator has admin permissions
- No explicit RBAC for WordPress namespace

**Recommendations**:
- Consider creating namespace-specific RBAC if needed
- WordPress pods don't need special Kubernetes permissions (they use IRSA for AWS access if needed)

**Status**: ⚠️ Acceptable for learning, but review for production

### 4. **Node Group IAM Role** ✅ HANDLED BY EKS MODULE

The EKS module automatically creates and attaches the necessary IAM role for node groups with:
- EKS Worker Node Policy
- EKS CNI Policy
- EC2 Container Registry ReadOnly
- AmazonEC2ContainerRegistryReadOnly

**Status**: ✅ Properly handled

## 📋 Pre-Apply Checklist

Before running `terraform apply`, verify:

- [ ] **Fix ALB Controller Service Account** (see Issue #1 above)
- [ ] **Verify Terraform IAM Permissions** (see Issue #2 above)
- [ ] **S3 Backend Bucket Exists**: `plastic-memory-terraform-state`
- [ ] **DynamoDB Table Exists**: `terraform-state-lock`
- [ ] **AWS Credentials Configured**: ✅ Verified (user: cezar)
- [ ] **Region**: eu-central-1
- [ ] **Kubernetes Version**: 1.34 (verify this is valid - might be too new)

## 🔧 Recommended Fixes

### Priority 1: Fix ALB Controller Service Account

Change in `main.tf`:
```terraform
{
  name  = "serviceAccount.create"
  value = "true"  # Change from false to true
}
```

### Priority 2: Verify Terraform Permissions

Run this command to test permissions:
```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::398879776142:user/cezar \
  --action-names ec2:CreateVpc,eks:CreateCluster,iam:CreateRole \
  --resource-arns "*"
```

Or simply try: `terraform plan` and check for permission errors.

## 📊 Summary

| Component | Status | Action Required |
|-----------|--------|-----------------|
| ALB IRSA Role | ✅ Good | None |
| CSI Driver IRSA Role | ✅ Good | None |
| ALB Service Account | ❌ Missing | **FIX REQUIRED** |
| Terraform Permissions | ⚠️ Unknown | **VERIFY REQUIRED** |
| EKS Permissions | ✅ Good | None |
| VPC Endpoints | ✅ Good | None |
| Node Group Permissions | ✅ Good | None |

## 🚀 Next Steps

1. **Fix the ALB controller service account issue** (change `serviceAccount.create` to `true`)
2. **Verify Terraform user has sufficient IAM permissions**
3. **Run `terraform plan` to check for any other issues**
4. **Then proceed with `terraform apply`**

