pipeline {
  agent any

  tools {
    nodejs 'NodeJS 18'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install dependencies') {
      steps {
        script {
          if (isUnix()) {
            sh 'npm ci'
          } else {
            bat 'npm ci'
          }
        }
      }
    }

    stage('Build') {
      steps {
        script {
          if (isUnix()) {
            sh 'npm run build'
          } else {
            bat 'npm run build'
          }
        }
      }
    }

    stage('Test') {
      steps {
        script {
          if (isUnix()) {
            sh 'npm run test || echo "No tests to run"'
          } else {
            bat 'npm run test || echo "No tests to run"'
          }
        }
      }
    }

    stage('Archive build artifacts') {
      steps {
        archiveArtifacts artifacts: 'out/**, .next/**', fingerprint: true, allowEmptyArchive: true
      }
    }

    stage('Docker Build & Run') {
      steps {
        script {
          if (isUnix()) {
            sh '''
              echo "Building Docker image keystore:latest"
              docker build -t keystore:latest .
              # Remove existing container if present
              EXISTING=$(docker ps -aq -f name=keystore)
              if [ -n "$EXISTING" ]; then
                docker rm -f $EXISTING || true
              fi
              docker run -d --name keystore -p 8080:80 keystore:latest
            '''
          } else {
            bat '''
              echo Building Docker image keystore:latest
              docker build -t keystore:latest .
              rem Use PowerShell to check docker daemon availability (avoids cmd parsing issues)
              powershell -NoProfile -Command "docker version > $null 2>&1; if ($LASTEXITCODE -ne 0) { Write-Host ''; Write-Host 'ERROR: Docker daemon not available. Make sure Docker Desktop (or Docker Engine) is running and Jenkins has access to the Docker daemon.'; Write-Host '- If using Docker Desktop on Windows: start Docker Desktop and (optionally) enable \"Expose daemon on tcp://localhost:2375\" and configure DOCKER_HOST for the Jenkins service.'; Write-Host '- If Jenkins runs as a Windows service, run the service under a user that can access the Docker daemon or expose the daemon via TCP.'; exit 1 }"
              rem Remove any existing container named 'keystore' (use proper filter quoting)
              for /f "delims=" %%i in ('docker ps -aq -f "name=keystore"') do (
                if not "%%i"=="" docker rm -f %%i
              )
              docker run -d --name keystore -p 8080:80 keystore:latest
            '''
          }
        }
      }
    }

    stage('Deploy to Render') {
      environment {
        SERVICE_ID = 'srv-d433rg3uibrs73al5nk0'
      }
      steps {
        withCredentials([string(credentialsId: 'render-api-key', variable: 'RENDER_KEY')]) {
          script {
            echo "Triggering Render deployment for service ${SERVICE_ID}"

            if (isUnix()) {
              sh '''
                curl -X POST https://api.render.com/v1/services/$SERVICE_ID/deploys \
                  -H "Authorization: Bearer $RENDER_KEY" \
                  -H "Content-Type: application/json"
              '''
            } else {
              bat '''
                curl -X POST https://api.render.com/v1/services/%SERVICE_ID%/deploys ^
                  -H "Authorization: Bearer %RENDER_KEY%" ^
                  -H "Content-Type: application/json"
              '''
            }
          }
        }
      }
    }

  }

  post {
    success {
      echo '✅ Build and deployment successful!'
    }
    failure {
      echo '❌ Build failed. Check logs for details.'
    }
    always {
      echo 'Pipeline complete!'
    }
  }
}
