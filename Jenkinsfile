pipeline {
    // Main Jenkins executor.
    // Node.js CI tasks run inside the required Node 16 container.
    agent any

    options {
        // Retain only the most recent 10 builds.
        buildDiscarder(logRotator(numToKeepStr: '10'))

        // Add timestamps to Jenkins console logs.
        timestamps()

        // Prevent concurrent builds from modifying the same workspace.
        disableConcurrentBuilds()

        // Perform source checkout explicitly.
        skipDefaultCheckout(true)
    }

    environment {
        // Docker Hub repository used for the application image.
        IMAGE_NAME = 'dude4693/isec6000-node-app'

        // Unique image tag based on the Jenkins build number.
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                // Check out source code from the configured SCM repository.
                checkout scm
            }
        }

        stage('Node.js CI') {
            agent {
                docker {
                    // Assessment requirement: Node 16 Docker build agent.
                    image 'node:16'

                    // Reuse the Jenkins workspace.
                    reuseNode true

                    // Execute CI tasks as a non-root user.
                    args '--user 1000:1000'
                }
            }

            stages {

                stage('Install Dependencies') {
                    steps {
                        // Record Node.js and npm versions in the build log.
                        sh 'node --version'
                        sh 'npm --version'

                        // Clean and reproducible dependency installation.
                        sh 'npm ci'
                    }
                }

                stage('Unit Tests') {
                    steps {
                        // Run automated tests.
                        // Test failure causes the pipeline to fail.
                        sh 'npm test'
                    }
                }

                stage('Dependency Security Scan') {
                    steps {
                        // Generate the full vulnerability report.
                        sh 'npm audit --json > npm-audit.json || true'

                        // Security gate:
                        // fail when High or Critical vulnerabilities exist.
                        sh 'npm audit --audit-level=high'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build both unique and latest image tags.
                sh '''
                    docker build \
                      -t ${IMAGE_NAME}:${IMAGE_TAG} \
                      -t ${IMAGE_NAME}:latest \
                      .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                // Retrieve Docker Hub credentials securely from Jenkins.
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | \
                          docker login \
                          --username "$DOCKERHUB_USERNAME" \
                          --password-stdin

                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            // Preserve the security scan report with the Jenkins build.
            archiveArtifacts(
                artifacts: 'npm-audit.json',
                allowEmptyArchive: true
            )
        }

        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'CI/CD pipeline failed. Review the build logs.'
        }
    }
}