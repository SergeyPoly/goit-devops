variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Kubernetes namespace for Argo CD"
}

variable "chart_version" {
  type        = string
  default     = "6.7.0"
  description = "Helm chart version for Argo CD"
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/SergeyPoly/goit-devops.git"
  description = "Git repository URL for Argo CD to sync application from"
}

variable "postgres_password" {
  type        = string
  description = "PostgreSQL password, injected into the django-app release as an Argo CD Application Helm parameter (never committed to Git)"
  sensitive   = true
}

variable "django_secret_key" {
  type        = string
  description = "Django SECRET_KEY, injected into the django-app release as an Argo CD Application Helm parameter (never committed to Git)"
  sensitive   = true
}