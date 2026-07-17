resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace
  }
}

# 1. Установка самого Argo CD
resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  wait    = false
  timeout = 900
}

# 2. Реєстрація Django Application в Argo CD (після установки Argo CD)
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace_v1.argocd.metadata[0].name

  set = [
    {
      name  = "repoUrl"
      value = var.repo_url
    }
  ]

  wait = false

  depends_on = [
    helm_release.argocd
  ]
}