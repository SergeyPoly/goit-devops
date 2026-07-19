output "jenkins_namespace" {
  value = kubernetes_namespace_v1.jenkins.metadata[0].name
}

output "kaniko_service_account" {
  description = "ServiceAccount (IRSA), яку Jenkinsfile використовує для агента Kaniko"
  value       = kubernetes_service_account_v1.kaniko.metadata[0].name
}

output "url_command" {
  description = "Port-forward до Jenkins UI (http://localhost:8081)"
  value       = "kubectl port-forward -n jenkins svc/jenkins 8081:8080"
}

output "admin_password_command" {
  description = "Команда для отримання пароля адміністратора Jenkins"
  value       = "kubectl exec -n jenkins jenkins-0 -c jenkins -- cat /run/secrets/additional/chart-admin-password"
}