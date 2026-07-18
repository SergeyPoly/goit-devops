variable "vpc_cidr_block" {
  type        = string
  description = "CIDR блок для VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "Список CIDR блоков для публичных подсетей"
}

variable "private_subnets" {
  type        = list(string)
  description = "Список CIDR блоков для приватных подсетей"
}

variable "availability_zones" {
  type        = list(string)
  description = "Список зон доступности (AZ)"
}

variable "vpc_name" {
  type        = string
  description = "Имя для тегов VPC"
}