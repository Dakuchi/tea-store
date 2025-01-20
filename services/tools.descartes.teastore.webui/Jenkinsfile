pipeline {
    agent any
    stages {
        stage('Build Service 1') {
            when {
                changeset "services/tools.descartes.teastore.webui/**"
            }
            steps {
                dir('services/tools.descartes.teastore.webui') {
                    pwd() 
                }
            }
        }
    }
}