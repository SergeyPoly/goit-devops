resource "kubernetes_namespace_v1" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.jenkins.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  wait    = false
  timeout = 900
}