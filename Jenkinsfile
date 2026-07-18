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
  serviceAccountName: default
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
                        git push origin HEAD:final-project
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
    }
}