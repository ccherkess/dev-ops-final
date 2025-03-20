terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

resource "yandex_compute_instance" "vm-build" {
  name = "vm-build"
  platform_id = var.yc_platform_id

  resources {
    core_fraction = 100
    cores  = 8
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size = 50
      type = var.yc_boot_disk_type
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default.id
    nat = true
  }

  provisioner "local-exec" {
    command = <<EOT
      until nc -z ${yandex_compute_instance.vm-build.network_interface[0].nat_ip_address} 22; do
        echo "Waiting for VM to be ready..."
        sleep 5
      done
      echo "VM is ready!"
    EOT
  }

  metadata = {
    user-data = sensitive(<<-EOT
      #cloud-config
      users:
        - name: user
          groups: sudo
          shell: /bin/bash
          sudo: 'ALL=(ALL) NOPASSWD:ALL'
          ssh_authorized_keys:
            - ${file(".ssh/id_rsa.pub")}
    EOT
    )
  }
}

output "instance_ip" {
  value = yandex_compute_instance.vm-build.network_interface[0].nat_ip_address
}
