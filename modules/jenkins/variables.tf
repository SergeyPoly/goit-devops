variable "namespace" {
  type        = string
  default     = "jenkins"
  description = "Kubernetes namespace for Jenkins"
}

variable "chart_version" {
  type        = string
  default     = "5.8.12"
  description = "Helm chart version for Jenkins"
}