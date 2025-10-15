pipeline {
    agent any

    environment {
        DOCKER_COMPOSE_VERSION = '3.8'
        MONITOR_SERVICE = 'petfinder-monitor.service'
        REPO_URL = 'https://github.com/delzilwilfred/petfinder-app.git'
        ALERT_LOG = '/var/log/petfinder_alerts.log'
        RECIPIENTS = 'henrydaniel2527@gmail.com'   // 🔔 Replace with your actual email
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo "📥 Cloning repository..."
                git branch: 'main', url: "${REPO_URL}"
            }
        }

        stage('Build Docker Images') {
            steps {
                echo "🐳 Building Docker images..."
                sh '''
                docker build -t petfinder-frontend -f Dockerfile-frontend .
                docker build -t petfinder-backend -f Dockerfile-backend .
                '''
            }
        }

        stage('Deploy Containers') {
            steps {
                echo "🚀 Deploying containers using Docker Compose..."
                sh '''
                docker-compose down || true
                docker-compose up -d
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "🔍 Checking running containers..."
                sh 'docker ps -a'
            }
        }

        stage('Start Log Monitor') {
            steps {
                echo "📊 Managing Petfinder log monitor service..."
                sh '''
                if systemctl is-active --quiet ${MONITOR_SERVICE}; then
                    echo "Restarting existing ${MONITOR_SERVICE}..."
                    sudo systemctl restart ${MONITOR_SERVICE}
                else
                    echo "Starting ${MONITOR_SERVICE}..."
                    sudo systemctl start ${MONITOR_SERVICE}
                fi

                echo "✅ Monitor service status:"
                sudo systemctl status ${MONITOR_SERVICE} --no-pager || true
                '''
            }
        }

        stage('Check for Alerts') {
            steps {
                echo "🔎 Checking for any recent alerts..."
                script {
                    def alerts = sh(script: "sudo tail -n 5 ${ALERT_LOG} || echo 'No alerts found.'", returnStdout: true).trim()
                    echo "Recent alerts:\n${alerts}"

                    if (!alerts.contains("No alerts") && alerts.length() > 0) {
                        echo "⚠️ Alerts detected! Sending email..."
                        emailext(
                            subject: "⚠️ Petfinder Alert - High Error Rate Detected",
                            body: """
                            Hello Henry 👋,

                            The Petfinder log monitor has detected recent issues on your server.

                            ================================
                            ${alerts}
                            ================================

                            Please check the backend logs or Jenkins console for more details.
                            """,
                            to: "${RECIPIENTS}"
                        )
                    } else {
                        echo "✅ No alerts found in the log file."
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ CI/CD Pipeline Completed Successfully!"
        }
        failure {
            echo "❌ Pipeline Failed. Check logs in Jenkins or container output."
        }
    }
}
