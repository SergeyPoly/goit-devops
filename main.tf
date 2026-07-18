terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Автентифікація провайдерів kubernetes/helm через exec (aws eks get-token),
# який запитує свіжий токен щоразу при зверненні до кластера.
# Свідомо НЕ через data.aws_eks_cluster(_auth): на цьому проєкті це двічі
# призводило до реальних збоїв - (1) aws_eks_cluster_auth.token живе лише
# ~15 хв, а довгий apply (EKS + node group + RDS + кілька Helm-релізів) це
# перевищує; (2) provider, сконфігурований через data source, що залежить
# від module.eks, під час plan іноді не встигає резолвитись і провайдер
# фолбечиться на localhost. module.eks.cluster_endpoint - це output модуля,
# обчислюється одразу після створення кластера, без цих проблем.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "lesson-7-eks"]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", "lesson-7-eks"]
    }
  }
}

# 1. Модуль S3 и DynamoDB для стейта
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "serhii-goit-terraform-state-bucket"
  table_name  = "terraform-locks"
}

# 2. Модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-5-vpc"
}

# 3. Модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
}

# 4. Модуль EKS кластера
module "eks" {
  source             = "./modules/eks"
  cluster_name       = "lesson-7-eks"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # t3.small пройшов account-level Free Tier guardrail, але вперся у ліміт
  # max-pods-per-node (ENI/IP), не в CPU/RAM: kubectl describe pod показував
  # "Too many pods" при 27-79% використання ресурсів. m7i-flex.large - теж
  # у списку free-tier-eligible для цього акаунта (aws ec2
  # describe-instance-types --filters Name=free-tier-eligible,Values=true),
  # і як "large" інстанс дає значно вищий ліміт подів на ноду.
  instance_types = ["m7i-flex.large"]
  desired_size   = 2
  min_size       = 1
  max_size       = 2
}

# 5. Модуль RDS: звичайна БД або Aurora-кластер залежно від rds_use_aurora
module "rds" {
  source = "./modules/rds"

  name       = "final-project-db"
  use_aurora = var.rds_use_aurora

  db_name  = "app_db"
  username = "app_user"
  password = var.rds_password

  # Free Tier guardrail цього акаунта відхиляє дефолтні 7 днів бекапів
  # (FreeTierRestrictionError на CreateDBInstance) - тримаємо мінімум.
  backup_retention_period = 1

  vpc_id              = module.vpc.vpc_id
  subnet_private_ids  = module.vpc.private_subnet_ids
  subnet_public_ids   = module.vpc.public_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  tags = {
    Project = "goit-devops"
    Lesson  = "final-project"
  }
}

# Модуль Jenkins
module "jenkins" {
  source     = "./modules/jenkins"
  depends_on = [module.eks]
}

# Модуль Argo CD
module "argo_cd" {
  source            = "./modules/argo_cd"
  repo_url          = "https://github.com/SergeyPoly/goit-devops.git"
  target_revision   = "final-project"
  postgres_password = var.postgres_password
  django_secret_key = var.django_secret_key
  postgres_host     = module.rds.endpoint

  depends_on = [module.eks]
}

# Модуль моніторингу: Prometheus + Grafana (kube-prometheus-stack)
module "monitoring" {
  source     = "./modules/monitoring"
  depends_on = [module.eks]
}