variable "aws_region" {
  type        = string
  description = "Регион AWS для развертывания"
  default     = "us-west-2"
}

variable "postgres_password" {
  type        = string
  description = "PostgreSQL password для django-app (задавати через terraform.tfvars або TF_VAR_postgres_password, не комітити)"
  sensitive   = true
}

variable "django_secret_key" {
  type        = string
  description = "Django SECRET_KEY для django-app (задавати через terraform.tfvars або TF_VAR_django_secret_key, не комітити)"
  sensitive   = true
}