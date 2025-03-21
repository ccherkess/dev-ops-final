pipeline {
    agent any

    environment {
        YC_TOKEN = credentials('yc-token')
        YC_CLOUD_ID = credentials('yc-cloud-id')
        YC_FOLDER_ID = credentials('yc-folder-id')

        DOCKER_DOMAIN = credentials('docker-domain')
        DOCKER_USERNAME = credentials('docker-username')
        DOCKER_PASSWORD = credentials('docker-password')

        APP_REPOSITORY = "https://github.com/boxfuse/boxfuse-sample-java-war-hello.git"
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
                dir('terraform/build') {
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
                dir('terraform/build') {
                    dir (".ssh") {
                        unstash 'ssh'
                    }

                    sh '''
                        terraform plan -no-color \
                        -var="yc_token=${YC_TOKEN}" \
                        -var="yc_cloud_id=${YC_CLOUD_ID}" \
                        -var="yc_folder_id=${YC_FOLDER_ID}"
                    '''

                    sh '''
                        terraform apply -auto-approve -no-color \
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
                dir('terraform/build') {
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

        stage('Build and push app image') {
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

                    script {
                        try {
                            sh '''
                                ansible-playbook build_app_image.yml \
                                    -i inventory.ini \
                                    --extra-vars "\
                                        repo_url=${APP_REPOSITORY} \
                                        dest_dir=/app \
                                        registry_url=${DOCKER_DOMAIN} \
                                        username=${DOCKER_USERNAME} \
                                        password=${DOCKER_PASSWORD} \
                                        image_tag=${BUILD_NUMBER}
                                    "
                            '''
                        } catch {
                            env.DESTROY_ON_FAILURE = true
                            throw e
                        }
                    }
                }
            }
        }

        stage('Terraform Destroy on Failure') {
            when {
                expression { env.DESTROY_ON_FAILURE == 'true' }
            }
            agent {
                docker {
                    image 'hashicorp/terraform:latest'
                    args '--entrypoint='
                }
            }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
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
