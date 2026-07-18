# Модуль `rds`

Універсальний Terraform-модуль для AWS-баз даних. Одним прапорцем перемикає
режим між звичайним `aws_db_instance` (PostgreSQL / MySQL / MariaDB тощо) і
Aurora-кластером (`aws_rds_cluster` + writer + опційні readers). В обох
режимах модуль однаково створює `DB Subnet Group`, `Security Group` та
`Parameter Group`, тож споживачу модуля не потрібно змінювати нічого, крім
вхідних змінних.

## Приклад використання

### Звичайний RDS (PostgreSQL), мінімальний виклик

```hcl
module "rds" {
  source = "./modules/rds"

  name     = "myapp-db"
  db_name  = "app_db"
  username = "app_user"
  # password не заданий -> модуль згенерує його автоматично

  vpc_id             = module.vpc.vpc_id
  subnet_private_ids = module.vpc.private_subnet_ids
}
```

### Той самий виклик, але MySQL замість PostgreSQL

```hcl
module "rds" {
  source = "./modules/rds"

  name     = "myapp-db"
  db_name  = "app_db"
  username = "app_user"

  engine                     = "mysql"
  engine_version              = "8.0"
  parameter_group_family_rds  = "mysql8.0"
  db_port                     = 3306 # опційно, модуль сам визначить 3306 з назви engine

  # Дефолтні параметри (max_connections, log_statement, work_mem) - специфічні
  # для PostgreSQL, для MySQL перевизначте їх сумісними параметрами:
  parameters = {
    max_connections = "200"
  }

  vpc_id             = module.vpc.vpc_id
  subnet_private_ids = module.vpc.private_subnet_ids
}
```

### Aurora-кластер (writer + 2 reader-репліки)

```hcl
module "rds" {
  source = "./modules/rds"

  name     = "myapp-db"
  db_name  = "app_db"
  username = "app_user"
  password = var.rds_password # sensitive-змінна, TF_VAR_rds_password

  use_aurora           = true
  engine_cluster       = "aurora-postgresql"
  engine_version_cluster = "16.4"
  aurora_replica_count = 2
  instance_class       = "db.r6g.large"

  vpc_id             = module.vpc.vpc_id
  subnet_private_ids = module.vpc.private_subnet_ids

  tags = {
    Environment = "production"
  }
}
```

> ⚠️ **Aurora не входить у AWS Free Tier** — навіть найменший `db.t*`/`db.r*`
> writer-інстанс тарифікується щогодини. Для навчальних/демо-цілей тримайте
> `use_aurora = false` (дефолт).

## Як перемкнути тип БД / engine / клас інстансу

| Що змінити | Яка змінна |
|---|---|
| Aurora-кластер замість звичайної БД | `use_aurora = true` |
| Engine звичайного RDS (postgres/mysql/mariadb) | `engine` + `engine_version` + `parameter_group_family_rds` (мають бути узгоджені, наприклад `postgres` / `16.4` / `postgres16`) |
| Engine Aurora-кластера | `engine_cluster` + `engine_version_cluster` + `parameter_group_family_aurora` (наприклад `aurora-postgresql` / `16.4` / `aurora-postgresql16`) |
| Розмір інстансу | `instance_class` (напр. `db.t3.micro` для Free Tier, `db.r6g.large` для продакшн-Aurora) |
| Кількість Aurora reader-реплік | `aurora_replica_count` (writer створюється завжди додатково, незалежно від цього числа) |
| Multi-AZ (лише звичайний RDS) | `multi_az = true` |
| Публічний доступ до БД | `publicly_accessible = true` (тоді subnet group будується з `subnet_public_ids`) |
| Параметри БД (max_connections тощо) | `parameters` (мапа `назва = значення`, застосовується і до `aws_db_parameter_group`, і до `aws_rds_cluster_parameter_group`) |

Актуальні комбінації `engine`/`engine_version`/`family` варто звірити командою:

```bash
aws rds describe-db-engine-versions --engine postgres --query 'DBEngineVersions[].EngineVersion'
aws rds describe-db-engine-versions --engine aurora-postgresql --query 'DBEngineVersions[].EngineVersion'
```

## Змінні

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `name` | `string` | — (обов'язкова) | Базове ім'я для інстансу/кластера та всіх супутніх ресурсів |
| `use_aurora` | `bool` | `false` | `true` → Aurora Cluster, `false` → звичайна `aws_db_instance` |
| `engine` | `string` | `"postgres"` | Engine звичайного RDS |
| `engine_version` | `string` | `"16.4"` | Версія engine звичайного RDS |
| `parameter_group_family_rds` | `string` | `"postgres16"` | Family parameter group звичайного RDS |
| `engine_cluster` | `string` | `"aurora-postgresql"` | Engine Aurora-кластера |
| `engine_version_cluster` | `string` | `"16.4"` | Версія engine Aurora-кластера |
| `parameter_group_family_aurora` | `string` | `"aurora-postgresql16"` | Family cluster parameter group Aurora |
| `aurora_replica_count` | `number` | `0` | Кількість Aurora reader-реплік (writer — завжди +1 до цього числа) |
| `instance_class` | `string` | `"db.t3.micro"` | Клас інстансу БД |
| `allocated_storage` | `number` | `20` | Обсяг диска в GB (лише звичайний RDS) |
| `db_name` | `string` | — (обов'язкова) | Ім'я бази даних всередині інстансу/кластера |
| `username` | `string` | `"app_user"` | Master username |
| `password` | `string` | `null` | Master password; якщо не задано — генерується автоматично |
| `vpc_id` | `string` | — (обов'язкова) | VPC для security group |
| `subnet_private_ids` | `list(string)` | — (обов'язкова) | Приватні підмережі для subnet group |
| `subnet_public_ids` | `list(string)` | `[]` | Публічні підмережі для subnet group (коли `publicly_accessible = true`) |
| `publicly_accessible` | `bool` | `false` | Чи матиме БД публічний endpoint |
| `allowed_cidr_blocks` | `list(string)` | `["10.0.0.0/16"]` | CIDR-блоки з доступом до порту БД |
| `db_port` | `number` | `null` | Порт БД; якщо `null` — визначається з engine (5432/3306) |
| `multi_az` | `bool` | `false` | Multi-AZ (лише звичайний RDS) |
| `backup_retention_period` | `number` | `7` | Днів зберігання бекапів |
| `skip_final_snapshot` | `bool` | `true` | Пропустити фінальний снапшот при видаленні |
| `deletion_protection` | `bool` | `false` | Захист від випадкового видалення |
| `parameters` | `map(string)` | `{max_connections="200", log_statement="ddl", work_mem="4096"}` | Параметри parameter group (дефолти орієнтовані на PostgreSQL) |
| `tags` | `map(string)` | `{}` | Теги для всіх ресурсів модуля |

## Виводи (`outputs`)

| Output | Опис |
|---|---|
| `endpoint` | Connection endpoint (writer endpoint для Aurora, address для звичайного RDS) |
| `reader_endpoint` | Aurora reader endpoint (`null` для звичайного RDS) |
| `port` | Порт БД |
| `db_name` | Ім'я бази даних |
| `username` | Master username |
| `password` | Master password (`sensitive`) |
| `security_group_id` | ID security group |
| `subnet_group_name` | Ім'я DB subnet group |
| `parameter_group_name` | Ім'я parameter group звичайного RDS (`null` для Aurora) |
| `cluster_parameter_group_name` | Ім'я cluster parameter group Aurora (`null` для звичайного RDS) |

## Ресурси, що створюються

- `aws_db_subnet_group` — спільний для обох режимів
- `aws_security_group` — спільний для обох режимів, ingress лише на порт БД з `allowed_cidr_blocks`
- `random_password` — авто-генерація пароля, якщо `password` не заданий
- Звичайний RDS (`use_aurora = false`): `aws_db_instance` + `aws_db_parameter_group`
- Aurora (`use_aurora = true`): `aws_rds_cluster` + `aws_rds_cluster_instance` (writer, і readers за `aurora_replica_count`) + `aws_rds_cluster_parameter_group`
