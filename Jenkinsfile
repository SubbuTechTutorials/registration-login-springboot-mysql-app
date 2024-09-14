pipeline {
    agent any

    environment {
        SPRINGBOOT_IMAGE = 'springboot-app'
        SPRINGBOOT_CONTAINER = 'springboot-app-container'
        MYSQL_IMAGE = 'mysql:8.0'
        MYSQL_CONTAINER = 'mysql-db'
        MYSQL_DATABASE = 'login_system'
        MYSQL_PORT = '3306'
        SPRING_DATASOURCE_URL = "jdbc:mysql://${MYSQL_CONTAINER}:${MYSQL_PORT}/${MYSQL_DATABASE}"
        DOCKER_NETWORK = 'my-network'
        SPRINGBOOT_PORT = '8081'
        SONARQUBE_URL = '<Your-SonarQube-URL>'
        NEXUS_DOCKER_REPO = '<DockerImagesRepo-Nexus-URL>'
        NEXUS_DOCKER_IMAGE = '<DockerImagesRepo>:<Repo-Port>/docker-hosted-repo/springboot-app'
        NEXUS_RELEASE_REPO = '<Your-Nexus-ReleaseRepo-URL>'
        NEXUS_SNAPSHOT_REPO = '<Your-Nexus-SnapshotRepo-URL>'
    }

    stages {
        stage('Clone Repository') {
            steps {
                echo 'Cloning repository...'
                git credentialsId: 'github-credentials', url: 'https://github.com/SubbuTechTutorials/registration-login-springboot-mysql-app.git'
            }
        }

        stage('Create Docker Network') {
            steps {
                echo 'Creating Docker network...'
                sh '''
                if ! docker network ls --format "{{.Name}}" | grep -q ${DOCKER_NETWORK}; then
                    docker network create ${DOCKER_NETWORK}
                fi
                '''
            }
        }

        stage('Start MySQL Container') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'db1dbd74-22a6-4e9e-8879-b256aec8f334', passwordVariable: 'MYSQL_ROOT_PASSWORD', usernameVariable: 'MYSQL_ROOT_USERNAME')]) {
                    echo 'Starting MySQL container...'
                    sh '''
                    if docker ps -a --format "{{.Names}}" | grep -q ${MYSQL_CONTAINER}; then
                        docker stop ${MYSQL_CONTAINER} || true
                        docker rm ${MYSQL_CONTAINER} || true
                    fi
                    
                    docker run -d --name ${MYSQL_CONTAINER} \
                    --network ${DOCKER_NETWORK} \
                    -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
                    -e MYSQL_DATABASE=${MYSQL_DATABASE} \
                    -p ${MYSQL_PORT}:${MYSQL_PORT} \
                    ${MYSQL_IMAGE} \
                    --default-authentication-plugin=mysql_native_password
                    '''
                }
            }
        }

        stage('Wait for MySQL') {
            steps {
                echo 'Waiting for MySQL to be ready...'
                sh '''
                until docker exec ${MYSQL_CONTAINER} mysqladmin ping -h "${MYSQL_CONTAINER}" --silent; do
                    echo "MySQL is not ready yet. Waiting..."
                    sleep 5
                done
                echo "MySQL is ready."
                '''
            }
        }


        stage('Build Spring Boot Docker Image') {
            steps {
                echo 'Building Docker image for Spring Boot app...'
                sh 'docker build -t ${SPRINGBOOT_IMAGE} .'
            }
        }

        stage('Start Spring Boot App Container') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'db1dbd74-22a6-4e9e-8879-b256aec8f334', usernameVariable: 'SPRING_DATASOURCE_USERNAME', passwordVariable: 'SPRING_DATASOURCE_PASSWORD')]) {
                    echo 'Starting Spring Boot app container...'
                    sh '''
                    if docker ps -a --format "{{.Names}}" | grep -q ${SPRINGBOOT_CONTAINER}; then
                        docker stop ${SPRINGBOOT_CONTAINER} || true
                        docker rm ${SPRINGBOOT_CONTAINER} || true
                    fi
                    
                    docker run -d --name ${SPRINGBOOT_CONTAINER} \
                    --network ${DOCKER_NETWORK} \
                    -e SPRING_DATASOURCE_URL=${SPRING_DATASOURCE_URL} \
                    -e SPRING_DATASOURCE_USERNAME=${SPRING_DATASOURCE_USERNAME} \
                    -e SPRING_DATASOURCE_PASSWORD=${SPRING_DATASOURCE_PASSWORD} \
                    -p ${SPRINGBOOT_PORT}:8080 ${SPRINGBOOT_IMAGE}
                    '''
                }
            }
        }

        stage('Verify Application') {
            steps {
                echo 'Verifying that the Spring Boot app is running...'
                sh '''
                echo "Sleeping for 30 seconds to ensure the app is fully up and running."
                sleep 30
                curl --fail http://<Your-Docker-Server-URL>:${SPRINGBOOT_PORT}/actuator/health || exit 1
                '''
            }
        }

        stage('Test Application') {
            steps {
                echo 'Running tests after containers are up...'
                sh '''
                echo "Starting Maven tests at $(date)"
                mvn clean test -DskipITs=false || (echo "Tests failed. Exiting..." && exit 1)
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    echo 'Running SonarQube analysis...'
                    withCredentials([string(credentialsId: 'sonarqube-credentials', variable: 'SONARQUBE_TOKEN')]) {
                        sh '''
                        mvn clean verify sonar:sonar \
                          -Dsonar.projectKey=registration-login-demo \
                          -Dsonar.host.url=${SONARQUBE_URL} \
                          -Dsonar.login=${SONARQUBE_TOKEN} \
                          -Dsonar.java.binaries=target/classes \
                        '''
                    }
                }
            }
        }

    stage('Deploy Artifact to Nexus') {
        steps {
            script {
                // Retrieve the version of the project from Maven
                 def version = sh(returnStdout: true, script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout").trim()

                // Determine the Nexus repository URL and repository ID based on version
                 def nexusRepoUrl = version.endsWith('-SNAPSHOT') ? "${NEXUS_SNAPSHOT_REPO}" : "${NEXUS_RELEASE_REPO}"
                 def repositoryId = version.endsWith('-SNAPSHOT') ? 'nexus-snapshots' : 'nexus-releases'

                // Deploy the artifact to Nexus
                 withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                    sh """
                     mvn clean deploy \
                        -DrepositoryId=${repositoryId} \
                        -Durl=${nexusRepoUrl} \
                        -Dusername=${NEXUS_USERNAME} \
                        -Dpassword=${NEXUS_PASSWORD}
                    """
            }
        }
    }
}

        stage('Push Docker Image to Nexus') {
            steps {
                echo 'Pushing Docker image to Nexus...'
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                    sh """
                    docker tag ${SPRINGBOOT_IMAGE} ${NEXUS_DOCKER_IMAGE}:latest
                    echo "${NEXUS_PASSWORD}" | docker login ${NEXUS_DOCKER_REPO} --username ${NEXUS_USERNAME} --password-stdin
                    docker push ${NEXUS_DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Cleanup Docker Images') {
            steps {
                echo 'Removing dangling and unused Docker images...'
                sh '''
                docker image prune -f
                docker system prune -f --volumes
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished'
            cleanWs()
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}
