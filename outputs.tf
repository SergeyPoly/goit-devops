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