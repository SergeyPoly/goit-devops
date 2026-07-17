output "jenkins_namespace" {
  value = kubernetes_namespace_v1.jenkins.metadata[0].name
}