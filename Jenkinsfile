pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'danishfintech/techsolutions-app'
        K8S_CLUSTER_NAME = 'danish-cluster'
        AWS_REGION = 'us-east-2'
        NAMESPACE = 'default'
        APP_NAME = 'techsolutions'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                git branch: 'main', url: 'https://github.com/khansaab-danish/microservices-ingress-danish.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    env.IMAGE_TAG = env.BUILD_NUMBER
                    def imageTag = "${DOCKER_HUB_REPO}:${IMAGE_TAG}"
                    def latestTag = "${DOCKER_HUB_REPO}:latest"

                    sh "docker build -t ${imageTag} ."
                    sh "docker tag ${imageTag} ${latestTag}"
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-creds', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin"
                        sh "docker push ${DOCKER_HUB_REPO}:${IMAGE_TAG}"
                        sh "docker push ${DOCKER_HUB_REPO}:latest"
                    }
                }
            }
        }

        stage('Configure AWS and Kubectl') {
            steps {
                echo 'Configuring AWS CLI and kubectl...'
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                        sh "aws configure set region ${AWS_REGION}"
                        sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${K8S_CLUSTER_NAME}"
                        sh "kubectl get nodes"
                    }
                }
            }
        }

        stage('Deploy Monitoring Stack') {
            steps {
                echo 'Deploying monitoring stack...'
                sh "kubectl apply -f monitoring/kube-state-metrics.yaml"
                sh "kubectl apply -f monitoring/prometheus-config.yaml"
                sh "kubectl apply -f monitoring/prometheus-deployment.yaml"
                sh "kubectl apply -f monitoring/grafana-deployment.yaml"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying application to Kubernetes...'
                script {
                    sh "sed -i 's|danish/techsolutions-app:latest|danishfintech/techsolutions-app:${IMAGE_TAG}|g' k8s/deployment.yaml"
                    sh "kubectl apply -f k8s/deployment.yaml --record"

                    // Wait for deployment rollout
                    sh """
                        if ! kubectl rollout status deployment/${APP_NAME}-deployment --timeout=300s; then
                            echo 'Rollout failed, describing pods for debugging...'
                            kubectl describe deployment ${APP_NAME}-deployment
                            kubectl describe pods -l app=${APP_NAME}
                            exit 1
                        fi
                    """

                    sh "kubectl get pods -l app=${APP_NAME}"
                    sh "kubectl get svc ${APP_NAME}-service"
                }
            }
        }

        stage('Deploy Ingress') {
            steps {
                echo 'Deploying Ingress resource...'
                sh "kubectl apply -f k8s/ingress.yaml"
                sleep(10)
                sh "kubectl get ingress ${APP_NAME}-ingress"
                sh "kubectl describe ingress ${APP_NAME}-ingress"
            }
        }

        stage('Get Ingress URL') {
            steps {
                echo 'Getting Ingress URL...'
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        waitUntil {
                            script {
                                def result = sh(
                                    script: "kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'",
                                    returnStdout: true
                                ).trim()

                                if (result && result != '') {
                                    env.INGRESS_URL = "http://${result}"
                                    echo "Ingress URL: ${env.INGRESS_UR_
