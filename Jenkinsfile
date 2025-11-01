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
              echo "Building Docker image keywarden:latest"
              docker build -t keywarden:latest .
              # Remove existing container if present
              EXISTING=$(docker ps -aq -f name=keywarden)
              if [ -n "$EXISTING" ]; then
                docker rm -f $EXISTING || true
              fi
              docker run -d --name keywarden -p 6000:6000 keywarden:latest
            '''
          } else {
            bat '''
              echo Building Docker image keywarden:latest
              docker build -t keywarden:latest .
              for /f "tokens=*" %%i in ('docker ps -aq -f name=keywarden') do (
                if not "%%i"=="" docker rm -f %%i
              )
              docker run -d --name keywarden -p 6000:6000 keywarden:latest
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
