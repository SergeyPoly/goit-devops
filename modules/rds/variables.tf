variable "name" {
  description = "Базове ім'я для інстансу/кластера та всіх супутніх ресурсів (subnet group, security group, parameter group)"
  type        = string
}

variable "use_aurora" {
  description = "true -> створюється Aurora Cluster (writer + опційні readers), false -> звичайна aws_db_instance"
  type        = bool
  default     = false
}

# --- Звичайний RDS engine (use_aurora = false) ---

variable "engine" {
  description = "Engine для звичайного RDS-інстансу: postgres, mysql, mariadb тощо"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Версія engine для звичайного RDS-інстансу"
  type        = string
  default     = "16.4"
}

variable "parameter_group_family_rds" {
  description = "Family parameter group для звичайного RDS (наприклад postgres16, mysql8.0)"
  type        = string
  default     = "postgres16"
}

# --- Aurora engine (use_aurora = true) ---

variable "engine_cluster" {
  description = "Engine для Aurora-кластера: aurora-postgresql або aurora-mysql"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version_cluster" {
  description = "Версія engine для Aurora-кластера"
  type        = string
  default     = "16.4"
}

variable "parameter_group_family_aurora" {
  description = "Family cluster parameter group для Aurora (наприклад aurora-postgresql16, aurora-mysql8.0)"
  type        = string
  default     = "aurora-postgresql16"
}

variable "aurora_replica_count" {
  description = "Кількість Aurora reader-реплік (writer-інстанс створюється завжди додатково до них)"
  type        = number
  default     = 0
}

# --- Спільні параметри ---

variable "instance_class" {
  description = "Клас інстансу БД. db.t3.micro/db.t4g.micro входять у Free Tier для звичайного RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Обсяг диска в GB (лише для звичайного RDS; Free Tier дозволяє до 20 GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Ім'я бази даних, яка створюється всередині інстансу/кластера"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "app_user"
}

variable "password" {
  description = "Master password. Якщо не задано (null), модуль автоматично згенерує безпечний пароль"
  type        = string
  default     = null
  sensitive   = true
}

variable "vpc_id" {
  description = "ID VPC, в якій буде створено security group для БД"
  type        = string
}

variable "subnet_private_ids" {
  description = "ID приватних підмереж (використовуються для subnet group, коли publicly_accessible = false)"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "ID публічних підмереж (використовуються для subnet group, коли publicly_accessible = true)"
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Чи матиме БД публічний endpoint. У продакшені тримайте false"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR-блоки, яким дозволено доступ до порту БД (security group ingress)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "db_port" {
  description = "Порт БД. Якщо null - визначається автоматично з engine (5432 для postgres, 3306 для mysql/mariadb)"
  type        = number
  default     = null
}

variable "multi_az" {
  description = "Multi-AZ розгортання (лише звичайний RDS). Не входить у Free Tier - для нього тримайте false"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Кількість днів зберігання автоматичних бекапів"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Пропустити фінальний снапшот при видаленні. true зручно для дев/демо-оточень"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Захист від випадкового видалення інстансу/кластера"
  type        = bool
  default     = false
}

variable "parameters" {
  description = <<-EOT
    Мапа параметрів БД, що застосовуються до parameter group (name = value).
    Дефолти орієнтовані на PostgreSQL - для MySQL/MariaDB перевизначте цю змінну
    сумісними з відповідним engine параметрами.
  EOT
  type        = map(string)
  default = {
    max_connections = "200"
    log_statement   = "ddl"
    work_mem        = "4096" # KB
  }
}

variable "tags" {
  description = "Теги, застосовані до всіх ресурсів модуля"
  type        = map(string)
  default     = {}
}
