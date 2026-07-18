variable "namespace" {
  type        = string
  default     = "monitoring"
  description = "Kubernetes namespace для Prometheus/Grafana"
}

variable "chart_version" {
  type        = string
  default     = "87.17.0"
  description = "Helm chart version для kube-prometheus-stack"
}
