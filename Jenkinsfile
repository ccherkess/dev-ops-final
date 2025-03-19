pipeline {
    agent any

    environment {
        SSH_KEYS_DIR = 'ssh-keys-dir'

        YC_TOKEN = credentials('yc-token')
        YC_CLOUD_ID = credentials('yc-cloud-id')
        YC_FOLDER_ID = credentials('yc-folder-id')
    }

    stages {
        stage('Create and Cache .ssh dir') {
            steps {
                dir('${SSH_KEYS_DIR}') {
                    sh 'ssh-keygen -t rsa -b 2048 -f id_rsa -N "" -q'
                    sh 'ls -a'
                    stash name: 'ssh', includes: '**'
                }
                sh 'ls -a'
            }
        }

        stage('Init Terraform') {
            agent {
                docker {
                    image 'hashicorp/terraform:latest'
                    args '--entrypoint='
                }
            }

            steps {
                dir('terraform') {
                    sh 'cp .terraformrc ~/'
                    sh 'terraform init'
                }
            }
        }

        stage('Create assembly VM') {
            agent {
                docker {
                    image 'hashicorp/terraform:latest'
                    args '--entrypoint='
                }
            }

            steps {
                dir('terraform') {
                    dir (".ssh") {
                        unstash 'ssh'
                    }

                    sh '''
                        terraform plan \
                        -var="yc_token=${YC_TOKEN}" \
                        -var="yc_cloud_id=${YC_CLOUD_ID}" \
                        -var="yc_folder_id=${YC_FOLDER_ID}"
                    '''

                    sh '''
                        terraform apply -auto-approve \
                        -var="yc_token=${YC_TOKEN}" \
                        -var="yc_cloud_id=${YC_CLOUD_ID}" \
                        -var="yc_folder_id=${YC_FOLDER_ID}"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'rm -rf ${SSH_KEYS_DIR}'
        }
    }
}
