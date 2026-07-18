output "monitoring_namespace" {
  value = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "grafana_port_forward_command" {
  description = "Port-forward до Grafana UI (http://localhost:3000)"
  value       = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
}

output "grafana_admin_password_command" {
  description = "Команда для отримання пароля адміністратора Grafana (логін: admin)"
  value       = "kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d"
}

output "prometheus_port_forward_command" {
  description = "Port-forward до Prometheus UI (http://localhost:9090)"
  value       = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
}
