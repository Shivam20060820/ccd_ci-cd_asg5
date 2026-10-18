pipeline {
    agent any

    triggers {
        // Automatically triggered when GitHub Webhook sends push events
        githubPush()
    }

    environment {
        APP_NAME = 'cloud-app'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('1. Checkout') {
            steps {
                echo '=== Stage 1: Pulling latest code triggered by GitHub Webhook ==='
                checkout scm
            }
        }

        stage('2. Build Docker Image') {
            steps {
                echo '=== Stage 2: Building Docker image (python-slim) ==='
                sh 'docker build -t ${APP_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('3. Load Image to Minikube') {
            steps {
                echo '=== Stage 3: Transferring image into Minikube cluster ==='
                sh 'minikube image load ${APP_NAME}:${IMAGE_TAG}'
            }
        }

        stage('4. Deploy to Kubernetes') {
            steps {
                echo '=== Stage 4: Deploying to Minikube via kubectl ==='
                sh 'kubectl apply -f k8s.yaml'
                sh 'kubectl rollout restart deployment/${APP_NAME}'
                sh 'kubectl rollout status deployment/${APP_NAME} --timeout=90s'
            }
        }

        stage('5. Health Verification') {
            steps {
                echo '=== Stage 5: Verifying Pods & Service ==='
                sh 'kubectl get pods -l app=${APP_NAME}'
                sh 'kubectl get svc cloud-app-service'
            }
        }
    }

    post {
        success {
            echo '=== SUCCESS: Deployment updated and running on AWS EC2 ==='
        }
        failure {
            echo '=== FAILURE: Pipeline encountered an error. Check logs above ==='
        }
    }
}
