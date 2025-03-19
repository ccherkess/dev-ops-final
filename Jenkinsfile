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
                stash name: 'ssh', includes: 'id_rsa, id_rsa.pub'
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
                        sh 'ls -a'
                    }

                    sh 'ls -a'

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
                dir('ansible') {
                    unstash 'ansible-inventory'
                    unstash 'ssh'

                    sh 'ls -l'
                    sh 'cat id_rsa'
                    sh 'cat id_rsa.pub'

                    input "Go?"
                    sh 'ansible  -i inventory.ini -m ping all'
                }
            }
        }
    }

    post {
        always {
            cleanWs(
                cleanWhenNotBuilt: false,
                deleteDirs: true,
                disableDeferredWipeout: true,
                notFailBuild: true
            )
        }
    }
}
