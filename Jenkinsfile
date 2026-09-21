pipeline {
    agent any

    stages {
        stage('Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/Shivam20060820/ccd_ci-cd_asg5.git'
            }
        }
        stage('Build') {
            steps {
                sh 'docker build -t cloud-app .'
            }
        }
        stage('Deploy') {
            steps {
                sh 'docker stop cloud-app || true'
                sh 'docker rm cloud-app || true'
                sh 'docker run -d --name cloud-app -p 5000:5000 cloud-app'
            }
        }
    }
}