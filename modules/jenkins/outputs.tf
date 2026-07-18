output "jenkins_namespace" {
  value = kubernetes_namespace_v1.jenkins.metadata[0].name
}

output "url_command" {
  description = "Команда для отримання зовнішньої адреси Jenkins"
  value       = "kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "admin_password_command" {
  description = "Команда для отримання пароля адміністратора Jenkins"
  value       = "kubectl exec -n jenkins jenkins-0 -c jenkins -- cat /run/secrets/additional/chart-admin-password"
}