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

variable "instance_types" {
  type        = list(string)
  default     = ["t3.small"]
  description = "EC2 instance types for the managed node group"
}

variable "desired_size" {
  type        = number
  default     = 2
  description = "Desired number of nodes in the managed node group"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum number of nodes in the managed node group"
}

variable "max_size" {
  type        = number
  default     = 2
  description = "Maximum number of nodes in the managed node group"
}