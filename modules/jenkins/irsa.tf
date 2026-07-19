# IRSA для агентів Jenkins (Kaniko): дозволяє поду отримати AWS-креденшели
# з правами лише на ECR push, замість того щоб успадковувати ширшу роль
# ноди (AmazonEC2ContainerRegistryPowerUser) через instance-профіль/IMDS.
data "aws_iam_policy_document" "kaniko_irsa_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:jenkins-kaniko"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "kaniko" {
  name               = "jenkins-kaniko-irsa"
  assume_role_policy = data.aws_iam_policy_document.kaniko_irsa_assume.json
}

resource "aws_iam_role_policy_attachment" "kaniko_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  role       = aws_iam_role.kaniko.name
}

# ServiceAccount, яку Jenkinsfile вказує як serviceAccountName для пода-агента
# (kaniko/aws-cli контейнери), щоб отримати права ролі вище через IRSA.
resource "kubernetes_service_account_v1" "kaniko" {
  metadata {
    name      = "jenkins-kaniko"
    namespace = kubernetes_namespace_v1.jenkins.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.kaniko.arn
    }
  }
}
