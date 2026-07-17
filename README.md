# goit-devops — Lesson 8-9: Jenkins + Argo CD CI/CD

Повний CI/CD-процес для Django-застосунку на AWS EKS: Jenkins (Kubernetes-агент +
Kaniko) збирає образ і пушить у ECR, оновлює тег у Helm-чарті та пушить у Git,
а Argo CD автоматично підхоплює зміни з Git і синхронізує застосунок у кластері.

Вся інфраструктура (VPC, EKS, ECR, Jenkins, Argo CD) розгортається через
Terraform, Jenkins і Argo CD встановлені як Helm-релізи модулями Terraform.

## Схема CI/CD

```mermaid
flowchart LR
    Dev[Розробник] -- git push app/ --> Repo[(GitHub\ngoit-devops\nlesson-8-9)]
    Repo --> Jenkins[Jenkins Pipeline]

    subgraph Jenkins Pipeline
        direction TB
        J1[Checkout scm] --> J2[Kaniko: build & push image]
        J2 --> J3[yq: update charts/django-app/values.yaml]
        J3 --> J4[git commit + push]
    end

    J2 -- docker push --> ECR[(Amazon ECR\nlesson-5-ecr)]
    J4 -- git push --> Repo

    Repo -- watch lesson-8-9 --> Argo[Argo CD Application\ndjango-app]
    Argo -- helm sync --auto-prune --self-heal --> EKS[(EKS\ndefault namespace)]
    EKS --> App[django-app-web + db]
    ECR -- image pull --> App
```

## Структура проєкту

```text
.
├── main.tf                    # Провайдери (aws/kubernetes/helm) + підключення модулів
├── backend.tf                 # S3 + DynamoDB бекенд стейту
├── variables.tf / outputs.tf  # Кореневі змінні та виводи
├── Jenkinsfile                 # Pipeline: Kaniko build → ECR push → update values.yaml → git push
│
├── modules/
│   ├── s3-backend/            # S3-бакет (versioning) + DynamoDB для стейту
│   ├── vpc/                   # VPC, 3 public + 3 private subnets, IGW, NAT Gateway
│   ├── ecr/                   # ECR репозиторій lesson-5-ecr + lifecycle policy
│   ├── eks/                   # EKS кластер, managed node group (2×t3.small),
│   │                          # launch template (IMDS hop-limit=2), EBS CSI addon,
│   │                          # дефолтний StorageClass gp3
│   ├── jenkins/                # Helm-реліз Jenkins (namespace jenkins)
│   └── argo_cd/                 # Helm-реліз Argo CD (namespace argocd) +
│       └── charts/              # локальний чарт з ресурсом Application (django-app)
│
└── charts/django-app/           # Helm-чарт застосунку, який синхронізує Argo CD
    ├── templates/                # deployment, service, configmap, secret, hpa, db-service
    └── values.yaml                # image.repository/tag, env, autoscaling
```

## Передумови

- Terraform >= 1.5, AWS CLI (налаштований `aws configure` з правами
  VPC/EKS/ECR/IAM/S3/DynamoDB), `kubectl`, `helm`.
- AWS-акаунт. **Увага**: EKS control plane (~$0.10/год), NAT Gateway та
  LoadBalancer-сервіси (Jenkins, Argo CD, django-app) **не покриваються Free
  Tier** — не забувай `terraform destroy` одразу після перевірки/здачі
  (розділ [Знищення інфраструктури](#знищення-інфраструктури)).

## 1. Як застосувати Terraform

### Перший запуск на чистому акаунті (bootstrap стейту)

`backend.tf` вказує на S3-бакет, який створюється тим самим кодом — це
класична проблема "курка-яйце". Тому перший запуск робиться у два кроки:

```powershell
# 1. Тимчасово закоментувати backend "s3" {...} у backend.tf
terraform init
terraform apply -target=module.s3_backend -auto-approve

# 2. Розкоментувати backend "s3" {...} назад
terraform init -migrate-state -force-copy
```

### Звичайний запуск (бакет уже існує)

```powershell
terraform init
terraform plan
terraform apply
```

Створює VPC, EKS (2×t3.small), ECR, встановлює Jenkins і Argo CD. Створення
EKS-кластера + нод-групи займає ~10-15 хв — це нормально, Terraform чекає,
поки AWS переведе ресурси у стан `ACTIVE`.

### Підключення kubectl

```powershell
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
```

## 2. Як перевірити Jenkins job

### Доступ до Jenkins

```powershell
kubectl get svc -n jenkins jenkins
# EXTERNAL-IP з колонки вище -> http://<EXTERNAL-IP>:8080

kubectl exec -n jenkins jenkins-0 -c jenkins -- cat /run/secrets/additional/chart-admin-password
# логін: admin, пароль — вивід команди вище
```

### Налаштування (робиться один раз вручну через UI)

1. **Credentials** → додати `github-credentials` (Username with password:
   username — твій GitHub-логін, password — GitHub Personal Access Token з
   правом `repo`, потрібен для `git push` з пайплайна).
2. **New Item** → Pipeline, вказати "Pipeline script from SCM":
   - SCM: Git, репозиторій `https://github.com/SergeyPoly/goit-devops.git`,
     гілка `lesson-8-9`, credential `github-credentials`, Script Path
     `Jenkinsfile`.
3. **Build Now**.

### Перевірка результату білда

```powershell
# Job виконав усі стадії без помилок (Kaniko build/push + git push)?
# -> дивись Console Output білда в Jenkins UI

# Новий тег дійсно у ECR:
aws ecr describe-images --region us-west-2 --repository-name lesson-5-ecr `
  --query "sort_by(imageDetails,&imagePushedAt)[-1].imageTags"

# Коміт з оновленим тегом дійсно у гілці lesson-8-9:
git log --oneline -3 origin/lesson-8-9
```

## 3. Як побачити результат в Argo CD

### Доступ до Argo CD

```powershell
kubectl get svc -n argocd argo-cd-argocd-server
# EXTERNAL-IP -> https://<EXTERNAL-IP> (сервер піднятий з --insecure, тому http теж працює)

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
# логін: admin, пароль — вивід команди вище (якщо секрет вже видалили — див. Settings -> Accounts в UI)
```

### Перевірка синхронізації

Application `django-app` (namespace `argocd`) стежить за `charts/django-app`
у гілці `lesson-8-9` і синхронізується автоматично (`prune: true`,
`selfHeal: true`) — після пуша Jenkins-пайплайном оновлення прилетить у
кластер без ручних дій.

```powershell
kubectl get application django-app -n argocd
# SYNC STATUS має бути Synced, HEALTH STATUS -> Healthy (може повисіти
# Progressing кілька секунд одразу після нового image tag)

# Образ, що реально крутиться в кластері (тег має збігатись з ECR/останнім комітом):
kubectl get deploy django-app-web -n default `
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# Зовнішня адреса застосунку:
kubectl get svc django-app-service -n default
```

Якщо Argo CD ще не побачив свіжий комміт (типовий інтервал поллінгу — 3 хв),
можна форсувати рефреш:

```powershell
kubectl patch application django-app -n argocd --type merge `
  -p "{\"metadata\":{\"annotations\":{\"argocd.argoproj.io/refresh\":\"hard\"}}}"
```

## Відомі обмеження

- `metrics-server` у кластері не встановлений, тому HPA (`django-app-hpa`) не
  бачить CPU-метрик (об'єкт створюється, але масштабування не спрацює, поки
  не поставити `metrics-server` окремим Helm-релізом).
- PostgreSQL (`db`) використовує `emptyDir` — дані не переживають
  перестворення пода, підходить лише для демонстрації.
- Кредити Jenkins (`github-credentials`) і Jenkins job створюються вручну
  через UI — в Terraform/JCasC це не автоматизовано.

## Знищення інфраструктури

Щоб не накопичувати рахунок за EKS/NAT/LoadBalancer-и:

```powershell
terraform destroy
```
