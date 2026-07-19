output "argocd_namespace" {
  value = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "url_command" {
  description = "Port-forward до Argo CD UI (https://localhost:8080, self-signed сертифікат)"
  value       = "kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:443"
}

output "admin_password_command" {
  description = "Команда для отримання початкового пароля адміністратора Argo CD"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}