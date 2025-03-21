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
  count = var.build ? 1 : 0
  platform_id = var.yc_platform_id
  name = "vm-build"

  resources {
    core_fraction = 100
    cores  = 8
    memory = 16
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
      until nc -z ${yandex_compute_instance.vm-build[0].network_interface[0].nat_ip_address} 22; do
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

output "build_instance_ip" {
  value = var.build ? yandex_compute_instance.vm-build[0].network_interface[0].nat_ip_address : null
}

resource "yandex_compute_instance" "vm-run" {
  count = var.run ? var.run_count : 0
  platform_id = var.yc_platform_id
  name = "vm-run-${count.index + 1}"

  resources {
    core_fraction = 100
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size = 25
      type = var.yc_boot_disk_type
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default.id
    nat = true
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

resource "null_resource" "wait_for_run_init" {
  count = var.run ? length(yandex_compute_instance.vm-run) : 0

  provisioner "local-exec" {
    command = <<-EOF
      until nc -z ${yandex_compute_instance.vm-run[count.index].network_interface[0].nat_ip_address} 22; do
          echo "Waiting for VM to be ready..."
          sleep 5
        done
        echo "VM is ready!"
    EOF
  }
}

output "run_instances_ips" {
  value = [for vm in yandex_compute_instance.vm-run : vm.network_interface[0].nat_ip_address]
}
