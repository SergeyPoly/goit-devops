variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for EKS Nodes"
}

variable "cluster_name" {
  type        = string
  default     = "django-cluster"
  description = "Name of the EKS Cluster"
}