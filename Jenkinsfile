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
        WAR_FILE_NAME = "hello-1.0.war"
        DOCKER_IMAGE_NAME = "hello"
        DOCKER_FILE = "../docker/Dockerfile"
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
                    sh 'terraform init -no-color'
                }
            }
        }

//         stage('Create Assembly VM') {
//             agent {
//                 docker {
//                     image 'hashicorp/terraform:latest'
//                     args '--entrypoint='
//                 }
//             }
//
//             steps {
//                 dir('terraform') {
//                     dir (".ssh") {
//                         unstash 'ssh'
//                     }
//
//                     sh '''
//                         terraform plan -no-color \
//                         -var="yc_token=${YC_TOKEN}" \
//                         -var="yc_cloud_id=${YC_CLOUD_ID}" \
//                         -var="yc_folder_id=${YC_FOLDER_ID}" \
//                         -var="build=true"
//                     '''
//
//                     sh '''
//                         terraform apply -auto-approve -no-color \
//                         -var="yc_token=${YC_TOKEN}" \
//                         -var="yc_cloud_id=${YC_CLOUD_ID}" \
//                         -var="yc_folder_id=${YC_FOLDER_ID}" \
//                         -var="build=true"
//                     '''
//                 }
//             }
//         }
//
//         stage('Generate and Cache Ansible Build Inventory') {
//             agent {
//                 docker {
//                     image 'hashicorp/terraform:latest'
//                     args '--entrypoint='
//                 }
//             }
//
//             steps {
//                 dir('terraform') {
//                     script {
//                         def instanceIp = sh(
//                             script: 'terraform output -json build_instance_ip',
//                             returnStdout: true
//                         );
//
//                         writeFile file: 'inventory.ini', text: """
//                             [vm]
//                             ${instanceIp}
//                         """
//
//                         stash name: 'ansible-inventory', includes: 'inventory.ini'
//                     }
//                 }
//             }
//         }
//
//         stage('Ansible Build And Push App Image') {
//             agent {
//                 docker {
//                     image 'alpine/ansible:latest'
//                     args '--entrypoint='
//                 }
//             }
//
//             steps {
//                 dir('ansible') {
//                     unstash 'ansible-inventory'
//                     unstash 'ssh'
//
//                     sh '''
//                         ansible-playbook build_app_image.yml \
//                             -i inventory.ini \
//                             --extra-vars "\
//                                 repo_url=${APP_REPOSITORY} \
//                                 registry_url=${DOCKER_DOMAIN} \
//                                 username=${DOCKER_USERNAME} \
//                                 password=${DOCKER_PASSWORD} \
//                                 image_tag=${BUILD_NUMBER} \
//                                 docker_image_name=${DOCKER_IMAGE_NAME} \
//                                 war_file=${WAR_FILE_NAME} \
//                                 dockerfile=${DOCKER_FILE}
//                             "
//                     '''
//                 }
//             }
//         }
//
//         stage('Terraform Destroy Assembly VM') {
//             agent {
//                 docker {
//                     image 'hashicorp/terraform:latest'
//                     args '--entrypoint='
//                 }
//             }
//             steps {
//                 dir('terraform') {
//                     sh '''
//                         terraform destroy -auto-approve -no-color \
//                             -var="yc_token=${YC_TOKEN}" \
//                             -var="yc_cloud_id=${YC_CLOUD_ID}" \
//                             -var="yc_folder_id=${YC_FOLDER_ID}" \
//                             -var="build=true"
//                     '''
//                 }
//             }
//         }

        stage('Create Run VMs') {
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
                        terraform plan -no-color \
                        -var="yc_token=${YC_TOKEN}" \
                        -var="yc_cloud_id=${YC_CLOUD_ID}" \
                        -var="yc_folder_id=${YC_FOLDER_ID}" \
                        -var="run=true" -var="run_count=3"
                    '''

                    sh '''
                        terraform apply -auto-approve -no-color \
                        -var="yc_token=${YC_TOKEN}" \
                        -var="yc_cloud_id=${YC_CLOUD_ID}" \
                        -var="yc_folder_id=${YC_FOLDER_ID}" \
                        -var="run=true" -var="run_count=3"
                    '''
                }
            }
        }

        stage('Generate and Cache Ansible Run Inventory') {
            agent {
                docker {
                    image 'hashicorp/terraform:latest'
                    args '--entrypoint='
                }
            }

            steps {
                dir('terraform') {
                    script {
                        def instanceIps = sh(
                            script: 'terraform output -json run_instances_ips',
                            returnStdout: true
                        )

                        def ips = new groovy.json.JsonSlurper().parseText(instanceIps)


                        writeFile file: 'inventory.ini', text: """
                            [vm]
                            ${ips.join("\n")}
                        """

                        stash name: 'ansible-inventory', includes: 'inventory.ini'
                    }
                }
            }
        }

        stage('Ansible Run App') {
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

                    sh '''
                        ansible-playbook run_app.yml \
                            -i inventory.ini \
                            --extra-vars "\
                                registry_url=${DOCKER_DOMAIN} \
                                username=${DOCKER_USERNAME} \
                                password=${DOCKER_PASSWORD} \
                                docker_image_name=${DOCKER_IMAGE_NAME} \
                                image_tag=1 \
                                app_port=8080
                            "
                    '''
                }
            }
        }

            stage('Terraform Destroy') {
                agent {
                    docker {
                        image 'hashicorp/terraform:latest'
                        args '--entrypoint='
                    }
                }
                steps {
                    input 'Destroy?'

                    dir('terraform') {
                        sh '''
                            terraform destroy -auto-approve -no-color \
                                -var="yc_token=${YC_TOKEN}" \
                                -var="yc_cloud_id=${YC_CLOUD_ID}" \
                                -var="yc_folder_id=${YC_FOLDER_ID}" \
                                -var="build=true"
                        '''
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
