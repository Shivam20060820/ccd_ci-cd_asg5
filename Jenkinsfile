pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        APP_NAME = 'cloud-app'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo '=== Stage 1: Pulling latest code from Git ==='
                git branch: 'main', url: 'https://github.com/Shivam20060820/ccd_ci-cd_asg5.git'
            }
        }

        stage('2. Build Docker Image') {
            steps {
                echo '=== Stage 2: Building Docker image (python:3.11-slim) ==='
                sh 'docker build -t ${APP_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('3. Load Image to Minikube') {
            steps {
                echo '=== Stage 3: Loading image into Minikube cluster ==='
                sh '''
                    sudo -u ubuntu minikube image load ${APP_NAME}:${IMAGE_TAG} || \
                    minikube image load ${APP_NAME}:${IMAGE_TAG} || true
                '''
            }
        }

        stage('4. Deploy to Kubernetes') {
            steps {
                echo '=== Stage 4: Deploying to Minikube via kubectl ==='
                sh '''
                    sudo -u ubuntu kubectl apply -f k8s.yaml || kubectl apply -f k8s.yaml
                    sudo -u ubuntu kubectl rollout restart deployment/${APP_NAME} || kubectl rollout restart deployment/${APP_NAME}
                    sudo -u ubuntu kubectl rollout status deployment/${APP_NAME} --timeout=90s || kubectl rollout status deployment/${APP_NAME} --timeout=90s
                    pkill -f "port-forward.*30000" 2>/dev/null || true
                    nohup sudo -u ubuntu kubectl port-forward --address 0.0.0.0 svc/cloud-app-service 30000:5000 >/dev/null 2>&1 &
                '''
            }
        }

        stage('5. Verify Deployment') {
            steps {
                echo '=== Stage 5: Verifying Pods & Service ==='
                sh '''
                    sudo -u ubuntu kubectl get pods -l app=${APP_NAME} || kubectl get pods -l app=${APP_NAME}
                    sudo -u ubuntu kubectl get svc cloud-app-service || kubectl get svc cloud-app-service
                '''
            }
        }
    }

    post {
        success {
            echo '🎉 SUCCESS: App successfully deployed & running at http://16.4.57.110:30000/'
        }
        failure {
            echo '❌ FAILURE: Pipeline encountered an error. Check console output above.'
        }
    }
}
