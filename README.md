# goit-devops
## Helm

Цей проєкт містить модульну структуру Terraform для автоматичного розгортання Kubernetes-кластера (Amazon EKS) у хмарі AWS (регіон `us-west-2`), а також Helm-чарт для деплою та автоматичного масштабування веб-застосунку Django із базою даних PostgreSQL.

## Структура проєкту

- `main.tf` — головний файл конфігурації, що об'єднує та викликає модулі.
- `backend.tf` — конфігурація віддаленого бекенду (S3) із блокуванням стейту (DynamoDB).
- `variables.tf` / `outputs.tf` — вхідні змінні та глобальне виведення створених ресурсів.
- `modules/` — каталог із ізольованими модулями інфраструктури:
    - `s3-backend` — створення S3-бакета для стейту та DynamoDB таблиці для локів.
    - `vpc` — побудова мережі (VPC, 3 публічні підмережі, 3 приватні підмережі, Internet Gateway, Route Tables).
    - `ecr` — створення Elastic Container Registry для Docker-образів з налаштованою політикою очищення.
    - `eks` — створення кластера Kubernetes (Amazon EKS) та Managed Node Groups.

## Інструкція з розгортання

1. Ініціалізація проєкту та розгортання інфраструктури AWS:
   ```powershell
   terraform init
   terraform apply -auto-approve
   ```
2. Підключення до створеного кластера EKS:
   ```powershell
   aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
   ```
3. Створення Docker-образу та пуш в Amazon ECR:
   ```powershell
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com
   docker build -t django-app:latest ./app
   docker tag django-app:latest YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/lesson-5-ecr:latest
   docker push YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/lesson-5-ecr:latest
   ```
4. Деплой застосунку в Kubernetes через Helm:
   ```powershell
   helm install django-release ./charts/django-app
   ```