pipeline {
    agent any

    environment {
        // Target Server Configuration
        TARGET_SERVER = '192.168.200.60'
        TARGET_USER   = 'root'
        SSH_CRED_ID   = 'ssh-serverportalpelanggan' // ID credentials di Jenkins
        DEPLOY_PATH   = '/var/www/portal-jakinet'
        IMAGE_NAME    = 'portal-jakinet'
        IMAGE_TAG     = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Archive Image') {
            steps {
                echo 'Saving image to tar.gz...'
                sh "docker save ${IMAGE_NAME}:${IMAGE_TAG} | gzip > ${IMAGE_NAME}.tar.gz"
            }
        }

        stage('Deploy to Target Server') {
            steps {
                sshagent(credentials: ["${SSH_CRED_ID}"]) {
                    echo 'Preparing directories on target server...'
                    sh "ssh -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_SERVER} 'mkdir -p ${DEPLOY_PATH}'"
                    
                    echo 'Transferring image archive and compose file...'
                    sh "scp -o StrictHostKeyChecking=no ${IMAGE_NAME}.tar.gz docker-compose.yml ${TARGET_USER}@${TARGET_SERVER}:${DEPLOY_PATH}/"
                    
                    echo 'Loading image and restarting container...'
                    sh """
                        ssh -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_SERVER} '
                            cd ${DEPLOY_PATH} && \
                            docker load < ${IMAGE_NAME}.tar.gz && \
                            docker compose down --remove-orphans && \
                            docker compose up -d && \
                            rm ${IMAGE_NAME}.tar.gz
                        '
                    """
                }
            }
        }

        stage('Cleanup local images') {
            steps {
                echo 'Cleaning up locally built files...'
                sh "rm -f ${IMAGE_NAME}.tar.gz"
                sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
            }
        }
    }

    post {
        success {
            echo 'Deployment completed successfully!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
