terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

locals {
  # Engine, що реально використовується, залежить від режиму (Aurora чи звичайний RDS)
  active_engine = var.use_aurora ? var.engine_cluster : var.engine

  # Порт визначається з engine, якщо не заданий явно
  default_port = length(regexall("mysql|mariadb", local.active_engine)) > 0 ? 3306 : 5432
  db_port      = coalesce(var.db_port, local.default_port)

  # Якщо пароль не переданий - використовуємо автоматично згенерований
  master_password = (var.password != null && var.password != "") ? var.password : random_password.rds.result
}

# Автогенерований master password (використовується, якщо var.password не задано).
# override_special уникає символів, які RDS не приймає (/, @, ", пробіл).
resource "random_password" "rds" {
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+[]{}"
}

# DB Subnet Group - спільний і для звичайного RDS, і для Aurora
resource "aws_db_subnet_group" "default" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.publicly_accessible ? var.subnet_public_ids : var.subnet_private_ids
  tags       = var.tags
}

# Security Group - спільний і для звичайного RDS, і для Aurora
resource "aws_security_group" "rds" {
  name        = "${var.name}-sg"
  description = "Security group for ${var.name} database"
  vpc_id      = var.vpc_id

  ingress {
    description = "DB access"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
