# petfinder-app

This is my demo website for practice purpose


 sudo apt update

 sudo apt install -y openjdk-17-jdk git docker.io

===========================================================================
 curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null


 echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

  
=======================if issue while update=============================

 sudo rm -f /etc/apt/sources.list.d/jenkins.list

 sudo rm -f /usr/share/keyrings/jenkins-keyring.asc

===========================================================================

 sudo apt update

 sudo apt install -y Jenkins

 sudo usermod -aG docker jenkins

 sudo systemctl enable jenkins

 sudo systemctl start Jenkins

 sudo systemctl status jenkins

===========================================================================

 sudo mkdir -p /usr/local/petfinder

 sudo cp monitor.sh /usr/local/petfinder/

 sudo chmod +x /usr/local/petfinder/monitor.sh

 sudo nano /etc/systemd/system/petfinder-monitor.service

To create the necessary files and configurations for deploying a PetFinder App using Docker and Jenkins, I’ll guide you step-by-step. Below are the steps to set up the frontend and backend folders, create Dockerfiles for both, a Jenkinsfile for Jenkins, and a monitoring script for monitoring Docker container logs.

# Step 1: Directory Structure

'''''''''''''''

/petfinder-app
  ├── /frontend
  │    ├── Dockerfile
  │    └── ... (other frontend files like React app)
  ├── /backend
  │    ├── Dockerfile
  │    └── ... (other backend files like Express app)
  ├── /docker-compose.yml
  ├── /monitor.sh
  ├── Jenkinsfile
  └── README.md

'''''''''''''''''

## Features

... (other sections of your README)

# Step 2: Create Frontend Dockerfile

 Frontend Dockerfile (frontend/Dockerfile)

# Stage 1: Build Angular app

FROM node:18-alpine as build
WORKDIR /app
COPY petfinder-frontend/package*.json ./
RUN npm install
COPY petfinder-frontend/ .
RUN npm run build --prod || npm run build

# Stage 2: Serve using Nginx
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]


**Step 3: Create Backend Dockerfile
**
# Use Node.js LTS
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY petfinder-backend/package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy source code
COPY petfinder-backend/ .

# Expose backend port (adjust if your app uses different one)
EXPOSE 5000

# Start the app
CMD ["npm", "start"]

# Step 4: Create docker-compose.yml

version: '3.8'

services:
  mongo:
    image: mongo:6
    container_name: mongo
    restart: unless-stopped
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: .
      dockerfile: Dockerfile-backend
    container_name: petfinder-backend
    restart: unless-stopped
    ports:
      - "5000:5000"
    depends_on:
      mongo:
        condition: service_healthy
    environment:
      - MONGODB_URI=mongodb://mongo:27017/petfinder
      - NODE_ENV=production
      - PORT=5000
    volumes:
      - ./backend-logs:/var/log/petfinder  # ✅ log folder mounted to host

  frontend:
    build:
      context: .
      dockerfile: Dockerfile-frontend
    container_name: petfinder-frontend
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      backend:
        condition: service_started
    environment:
      - NODE_ENV=production

volumes:
  mongo-data:

# Step 5: Create Monitor Script for Logs

#!/usr/bin/env bash
# monitor.sh - Basic log monitor + alerting + rotation
 # Usage: sudo ./monitor.sh /var/log/petfinder.log


LOG_FILE=${1:-/var/log/petfinder.log}
ALERT_FILE=/var/log/petfinder_alerts.log
TEMP_LOG=/tmp/petfinder_monitor.tmp
THRESHOLD=5 # errors
WINDOW_SECONDS=60 # 1 minute
ROTATE_SIZE=$((1024*1024*5)) # 5MB


mkdir -p $(dirname "$ALERT_FILE")


# Ensure log exists
touch "$LOG_FILE"


# tail the log and process lines
# This implementation will run continuously; run under systemd or screen in background


while true; do
# capture current timestamp and check how many 5xx entries in last WINDOW_SECONDS
end_ts=$(date +%s)
start_ts=$((end_ts - WINDOW_SECONDS))


# use awk to filter lines by timestamps if log has ISO timestamps; fallback: scan last N lines
# Here we use a simple heuristic: check last 1000 lines for " 5xx " or "HTTP/1.1" 500
count=$(tail -n 1000 "$LOG_FILE" | egrep -c "\b5[0-9]{2}\b|HTTP/1\.[01]\"\s+500|status\s*:\s*500")


if [ "$count" -ge "$THRESHOLD" ]; then
echo "$(date -Iseconds) ALERT: High error rate detected: $count errors in last ${WINDOW_SECONDS}s" | tee -a "$ALERT_FILE"
fi


# Log rotation
filesize=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
if [ "$filesize" -ge "$ROTATE_SIZE" ]; then
mv "$LOG_FILE" "$LOG_FILE.$(date +%Y%m%d%H%M%S)"
gzip -9 "$LOG_FILE."* || true
touch "$LOG_FILE"
echo "$(date -Iseconds) INFO: Rotated log" >> "$ALERT_FILE"
fi


sleep 10
done

Make the script executable:
chmod +x monitor.sh

Run the script to monitor the logs:
./monitor.sh


# Step 6: Create Jenkinsfile for CI/CD






 
  
    pipeline{
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
                echo '📊 Managing Petfinder log monitor service...'
                withCredentials([usernamePassword(credentialsId: 'sudo-creds', passwordVariable: 'SUDO_PASS', usernameVariable: 'SUDO_USER')]) {
                    sh '''
                        if systemctl is-active --quiet ${MONITOR_SERVICE}; then
                            echo "Restarting existing ${MONITOR_SERVICE}..."
                            echo "$SUDO_PASS" | sudo -S systemctl restart ${MONITOR_SERVICE}
                        else
                            echo "Starting ${MONITOR_SERVICE}..."
                            echo "$SUDO_PASS" | sudo -S systemctl start ${MONITOR_SERVICE}
                        fi

                        echo "✅ Monitor service status:"
                        echo "$SUDO_PASS" | sudo -S systemctl status ${MONITOR_SERVICE} --no-pager || true
                    '''
                }
            }
        }

        stage('Check for Alerts') {
            steps {
                echo "🔎 Checking for any recent alerts..."
                withCredentials([usernamePassword(credentialsId: 'sudo-creds', passwordVariable: 'SUDO_PASS', usernameVariable: 'SUDO_USER')]) {
                    script {
                        def alerts = sh(script: "echo \"$SUDO_PASS\" | sudo -S tail -n 5 ${ALERT_LOG} || echo 'No alerts found.'", returnStdout: true).trim()
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



# Step 7: Setup Jenkins

1. Install Jenkins: If you don’t have Jenkins set up, you can follow the Jenkins installation guide Above
2. Create a new Jenkins job:
   .Create a new Pipeline job.
   .In the Pipeline section, set the Definition to Pipeline script from SCM.
   .Enter the repository URL (e.g., GitHub) where your code is hosted.
   .Set the Script Path to Jenkinsfile.
3. Run the Jenkins job to build, deploy, and monitor your containers.

# Step 8: Automate Deployment

You can integrate with a cloud platform (like AWS, Azure, or GCP) or container orchestration tools (like Kubernetes) to deploy the containers automatically, but that’s beyond this current setup.

# Step 9: Additional Configuration (Optional)

1. Nginx Configuration: You can configure Nginx in your frontend Dockerfile if you need specific settings for production (e.g., reverse proxy, SSL).
2. Environment Variables: For sensitive data like API keys or credentials, you can use Docker’s environment variable options or a .env file.

# Summary

1. Created Dockerfile for both frontend and backend.
2. Configured docker-compose.yml for multi-container deployment.
3. Created a monitoring script to check the logs of running containers.
4. Set up a Jenkins pipeline (Jenkinsfile) for continuous integration and deployment.

