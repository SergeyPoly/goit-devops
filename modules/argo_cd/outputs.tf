output "argocd_namespace" {
  value = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "url_command" {
  description = "Команда для отримання зовнішньої адреси Argo CD"
  value       = "kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "admin_password_command" {
  description = "Команда для отримання початкового пароля адміністратора Argo CD"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}