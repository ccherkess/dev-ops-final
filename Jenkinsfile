pipeline {
    agent any

    environment {
        YC_TOKEN = credentials('yc-token')
        YC_CLOUD_ID = credentials('yc-cloud-id')
        YC_FOLDER_ID = credentials('yc-folder-id')
    }

    stages {
        stage('Create and Cache .ssh dir') {
            steps {
                sh 'ssh-keygen -t rsa -b 2048 -f id_rsa -N "" -q'
                stash name: 'ssh', includes: '**'
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

        stage('Generate and Cache Ansible Inventory') {
            agent {
                docker {
                    image 'hashicorp/terraform:latest'
                    args '--entrypoint='
                }
            }

            steps {
                dir('terraform') {
                    script {
                        def instanceIp = sh(
                            script: 'terraform output -json instance_ip',
                            returnStdout: true
                        );

                        writeFile file: 'inventory.ini', text: """
                            [vm]
                            ${instanceIp}

                            [defaults]
                            host_key_checking = false
                            ansible_ssh_private_key_file = ${WORKSPACE}/.ssh
                        """

                        stash name: 'ansible-inventory', includes: 'inventory.ini'
                    }
                }
            }
        }

        stage('TEST ansible') {
            agent {
                docker {
                    image 'alpine/ansible:latest'
                    args '--entrypoint='
                }
            }

            steps {
                unstash 'ansible-inventory'

                dir ('${WORKSPACE}/.ssh') {
                    unstash 'ssh'
                }

                sh 'ls -l'
                sh 'pwd'

                input "Go?"
                sh 'ansible  -i inventory.ini -m ping all'
            }
        }
    }

    post {
        always {
            sh 'rm -rf id_rsa'
            sh 'rm -rf id_rsa.pub'
        }
    }
}
