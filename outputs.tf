output "s3_bucket_arn" {
  value       = module.s3_backend.s3_bucket_arn
  description = "ARN созданного S3 бакета"
}

output "dynamodb_table_name" {
  value       = module.s3_backend.dynamodb_table_name
  description = "Имя таблицы DynamoDB для блокировок"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID созданной VPC"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URL созданного ECR репозитория"
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "jenkins_url_command" {
  value = module.jenkins.url_command
}

output "jenkins_admin_password_command" {
  value = module.jenkins.admin_password_command
}

output "argocd_url_command" {
  value = module.argo_cd.url_command
}

output "argocd_admin_password_command" {
  value = module.argo_cd.admin_password_command
}

output "rds_endpoint" {
  description = "Connection endpoint бази даних (writer endpoint для Aurora)"
  value       = module.rds.endpoint
}

output "rds_reader_endpoint" {
  description = "Aurora reader endpoint (null для звичайного RDS)"
  value       = module.rds.reader_endpoint
}

output "rds_port" {
  value = module.rds.port
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "rds_username" {
  value = module.rds.username
}

output "rds_password" {
  value     = module.rds.password
  sensitive = true
}