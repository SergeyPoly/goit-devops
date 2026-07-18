pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  serviceAccountName: jenkins-kaniko
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - sleep
    args:
    - 99d
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  - name: aws-cli
    image: amazon/aws-cli:latest
    command:
    - sleep
    args:
    - 99d
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  - name: git-tools
    image: alpine/git:latest
    command:
    - sleep
    args:
    - 99d
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
  volumes:
  - name: docker-config
    emptyDir: {}
'''
        }
    }

    environment {
        AWS_REGION     = 'us-west-2'
        ECR_REPO       = '645819131673.dkr.ecr.us-west-2.amazonaws.com/lesson-5-ecr'
        APP_PATH       = './app'
        HELM_VALUES    = 'charts/django-app/values.yaml'
        GIT_CRED_ID    = 'github-credentials' // Имя секретного ключа/токена в Jenkins
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Docker Image (Kaniko)') {
            steps {
                container('aws-cli') {
                    // ServiceAccount jenkins-kaniko (IRSA) дає права ECR push -
                    // генеруємо docker config.json для Kaniko з ECR-токена,
                    // не покладаючись на права ролі ноди.
                    sh """
                    mkdir -p /kaniko/.docker
                    PASSWORD=\$(aws ecr get-login-password --region ${AWS_REGION})
                    AUTH=\$(printf 'AWS:%s' "\$PASSWORD" | base64 -w0)
                    cat > /kaniko/.docker/config.json <<EOF
{"auths":{"${ECR_REPO.split('/')[0]}":{"auth":"\$AUTH"}}}
EOF
                    """
                }
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                      --context=dir://${APP_PATH} \
                      --dockerfile=${APP_PATH}/Dockerfile \
                      --destination=${ECR_REPO}:${BUILD_NUMBER} \
                      --destination=${ECR_REPO}:latest
                    """
                }
            }
        }

        stage('Update Helm Values in Git') {
            steps {
                container('git-tools') {
                    sh """
                    # Установка yq для редактирования YAML
                    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
                    chmod +x /usr/bin/yq

                    # .git создан процессом агента (другой UID) - разрешаем работу с ним
                    git config --global --add safe.directory '*'

                    # Обновление тега образа в values.yaml
                    yq eval '.image.tag = "${BUILD_NUMBER}"' -i ${HELM_VALUES}

                    # Настройка Git
                    git config user.email "jenkins@ci.com"
                    git config user.name "Jenkins CI"
                    git add ${HELM_VALUES}
                    git commit -m "ci: update image tag to ${BUILD_NUMBER} [skip ci]" || echo "No changes to commit"
                    """

                    withCredentials([usernamePassword(credentialsId: env.GIT_CRED_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                        // Одинарные кавычки - без Groovy-интерполяции секрета в текст скрипта
                        sh '''
                        git remote set-url origin "https://${GIT_USER}:${GIT_TOKEN}@github.com/SergeyPoly/goit-devops.git"
                        git push origin HEAD:lesson-8-9
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully! Argo CD will auto-sync the new version (${BUILD_NUMBER})."
        }
        failure {
            echo "Pipeline failed!"
        }
        always {
            cleanWs()
        }
    }
}