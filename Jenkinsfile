pipeline {
    agent any
    tools {
       terraform 'Terraform v1.3.6'
    } 
    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/sundeepbhatia1989/Az_SimpleLinuxVM.git'
            }
        }
               stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform plan'){
            steps {
                sh 'terraform plan'
            }
        }
        stage('Terraform fmt') {
            steps {
                sh 'terraform fmt'
            }
        }
        
            stage('Terraform validate') {
            steps {
                sh 'terraform validate'
            }
        }
            stage('Terraform approve') {
            steps {
                sh 'terraform apply --auto-approve'
            }
        }
           stage('Terraform destroy') {
            steps {
                sh 'terraform destroy --auto-approve'
            }
        }
    }
}
