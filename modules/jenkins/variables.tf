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

variable "oidc_provider_arn" {
  type        = string
  description = "ARN OIDC-провайдера EKS-кластера (для IRSA trust policy Kaniko-ServiceAccount)"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL OIDC-провайдера EKS-кластера без https:// (для IRSA trust policy Kaniko-ServiceAccount)"
}