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

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
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
  postgres_password = var.postgres_password
  django_secret_key = var.django_secret_key

  depends_on = [module.eks]
}

# 5. Модуль RDS: звичайна БД або Aurora-кластер залежно від rds_use_aurora
module "rds" {
  source = "./modules/rds"

  name       = "lesson-db-module"
  use_aurora = var.rds_use_aurora

  db_name  = "app_db"
  username = "app_user"
  password = var.rds_password

  vpc_id              = module.vpc.vpc_id
  subnet_private_ids  = module.vpc.private_subnet_ids
  subnet_public_ids   = module.vpc.public_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  tags = {
    Project = "goit-devops"
    Lesson  = "lesson-db-module"
  }
}