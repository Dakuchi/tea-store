pipeline {
    agent any
    tools {
        maven 'maven'
        sonarScanner 'Sonar'
    }
    environment {
        VERSION = "" // Placeholder for the version derived from the milestone title
        DOCKER_REGISTRY = 'Dakuchi'
        DOCKER_CREDENTIALS_ID = 'docker hub credentials' // Jenkins DockerHub credentials ID
        //SONARQUBE_ENV = 'SonarQube'
        //GITHUB_TOKEN = credentials('github-token')   // Jenkins GitHub token ID
    }
    options {
        skipStagesAfterUnstable()
    }
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                git branch: 'development', url: 'https://github.com/Dakuchi/tea-store.git'
            }
        }
        stage('Build and Unit Tests') {
            steps {
                echo 'Building and running unit tests...'
                sh 'mvn clean install'
            }
        }
        stage('Code Analysis') {
            environment {
                scannerHome = tool 'Sonar'
            }
            steps {
                script {
                    withSonarQubeEnv('Sonar') {  // Make sure this matches your SonarQube configuration name in Jenkins
                        sh '''
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=teastore \
                            -Dsonar.projectName=TeaShop \
                            -Dsonar.projectVersion=1.0 \
                            -Dsonar.sources=src
                        '''
                    }
                }
            }
        }
        stage('Deploy for Integration Tests') {
            steps {
                echo 'Deploying services using Docker Compose...'
                sh '''
                    cd tools/
                    ./build_docker.sh
                    cd ..
                    sed -i 's/descartesresearch\\///g' examples/docker/docker-compose_default.yaml
                    docker-compose -f examples/docker/docker-compose_default.yaml up -d
                '''
            }
        }
        stage('Integration Tests (Cypress)') {
            steps {
                echo 'Running Cypress tests...'
                dir('e2e-tests') {
                    sh '''
                        npx cypress run --config baseUrl=http://localhost:8080
                    '''
                }
            }
        }
        stage('Cleanup') {
            steps {
                echo 'Cleaning up Docker containers...'
                sh 'docker-compose -f examples/docker/docker-compose_default.yaml down --volumes --remove-orphans'
            }
        }
        stage('Prepare Release') {
            when {
                expression {
                    return env.BRANCH_NAME == 'main'
                }
            }
            steps {
                echo 'Preparing release...'
                script {
                    // Extract version from milestone (mocked for now)
                    env.VERSION = '1.0.0' // Replace this with logic to fetch milestone
                }
                sh '''
                    sed -i "s/<teastoreversion>.*</<teastoreversion>${VERSION}<</" pom.xml
                    git config user.email "action@github.com"
                    git config user.name "GitHub Action"
                    git commit -m "Automated version bump to ${VERSION}" -a
                    git push origin development
                '''
            }
        }
        stage('Merge to main') {
            when {
                branch 'development'
            }
            steps {
                echo 'Merging development into main...'
                sh '''
                    git checkout main
                    git merge development -m "Automated merge from development to main"
                    git push origin main
                '''
            }
        }
        stage('Build and Push Docker Images') {
            steps {
                echo 'Building and pushing Docker images...'
                script {
                    def services = [
                        'teastore-base',
                        'teastore-recommender',
                        'teastore-webui',
                        'teastore-image',
                        'teastore-auth',
                        'teastore-persistence',
                        'teastore-registry',
                        'teastore-db',
                        'teastore-kieker-rabbitmq'
                    ]
                    services.each { service ->
                        sh """
                            docker build -t ${DOCKER_REGISTRY}/${service}:latest -t ${DOCKER_REGISTRY}/${service}:${VERSION} ./services/tools.descartes.teastore.${service.replace('-', '.')}
                            docker push ${DOCKER_REGISTRY}/${service}:latest
                            docker push ${DOCKER_REGISTRY}/${service}:${VERSION}
                        """
                    }
                }
            }
        }
    }
    post {
        success {
            echo 'Pipeline executed successfully.'
        }
        failure {
            echo 'Pipeline failed!'
        }
        cleanup {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
