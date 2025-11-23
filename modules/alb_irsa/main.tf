resource "aws_iam_policy" "alb_policy" {
  name        = "${var.cluster_name}-alb-controller"
  description = "Policy for ALB Load Balancer Controller"

  policy = file("${path.module}/iam_policy.json") # reference to the policy file in module
}

resource "aws_iam_role" "alb_irsa" {
  name = "${var.cluster_name}-alb-irsa"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {#aws_iam_policy_document.assume_role from above is defined here
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "alb_attachment" {
  policy_arn = aws_iam_policy.alb_policy.arn
  role       = aws_iam_role.alb_irsa.name #this acceses aws_iam_role with the name alb_irsa from above and acceses the constructed name: alb-irsa-<cluster_name>
}#and this is how a role name is created
