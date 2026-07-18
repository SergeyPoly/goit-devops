output "endpoint" {
  description = "Connection endpoint (writer endpoint для Aurora, address для звичайного RDS)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].address
}

output "reader_endpoint" {
  description = "Aurora reader endpoint (null для звичайного RDS)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

output "port" {
  description = "Порт, на якому слухає БД"
  value       = local.db_port
}

output "db_name" {
  description = "Ім'я бази даних"
  value       = var.db_name
}

output "username" {
  description = "Master username"
  value       = var.username
}

output "password" {
  description = "Master password (згенерований автоматично, якщо var.password не задано)"
  value       = local.master_password
  sensitive   = true
}

output "security_group_id" {
  description = "ID security group бази даних"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "Ім'я DB subnet group"
  value       = aws_db_subnet_group.default.name
}

output "parameter_group_name" {
  description = "Ім'я parameter group (звичайний RDS) або null для Aurora"
  value       = var.use_aurora ? null : aws_db_parameter_group.standard[0].name
}

output "cluster_parameter_group_name" {
  description = "Ім'я cluster parameter group (Aurora) або null для звичайного RDS"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.aurora[0].name : null
}
