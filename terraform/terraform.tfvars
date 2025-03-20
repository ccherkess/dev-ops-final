yc_users_config = <<-EOT
  #cloud-config
  users:
    - name: user
      groups: sudo
      shell: /bin/bash
      sudo: 'ALL=(ALL) NOPASSWD:ALL'
      ssh_authorized_keys:
        - ${file(".ssh/id_rsa.pub")}
EOT