variable "ecr_name" {
  type        = string
  description = "Имя репозитория ECR"
}

variable "scan_on_push" {
  type        = bool
  description = "Включить сканирование образов на уязвимости при пуше"
  default     = true
}