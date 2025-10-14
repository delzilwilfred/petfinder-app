pipeline {
    agent any

    environment {
        DOCKER_COMPOSE_VERSION = '3.8'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/delzilwilfred/petfinder-app.git'
            }
        }

        stage('Build Docker Images') {
            steps {
                sh 'docker build -t petfinder-frontend -f Dockerfile-frontend .'
                sh 'docker build -t petfinder-backend -f Dockerfile-backend .'
            }
        }

        stage('Run Containers') {
            steps {
                sh 'docker-compose down || true'
                sh 'docker-compose up -d'
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'docker ps -a'
            }
        }
    }

    post {
        success {
            echo "✅ CI/CD Pipeline Completed Successfully!"
        }
        failure {
            echo "❌ Pipeline Failed. Check logs in Jenkins."
        }
    }
}
