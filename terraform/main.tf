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

  metadata = {
    ssh-keys = "root:${file(".ssh/id_rsa.pub")}"
    ssh-keys = "root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyOAj0Ap/wNzH2Jsqv0fQ1Qot1MGMrvVtm/3P81aFsx4puUT+Et4geekGwx5lol0jSUMsUnwguA/8pEsOcMPvgymfUZBlA3+BXn8FWkWnWr+CuIsHDZbkUsnIKTp9xR0SjOmB7ZwaJz7EZJoTgekFihVp4U++cG8KPQWPuX/Zl8IYXKamHhynbsrH5HUG4YlOBLC4fTEbocYHzBFTzY3ZhmCt+p50Cc+nlC/u8DSey66LByW9tvDzTnC0r3Wyxj5xRao1wmHtIKvbgA8i2tSFrHrb3ndPhfjojUDpP+S/tCQU0vQELWZmv12lhvkRnynwUWG5ddPD+mBrKqEXTgq2/UxtUCggO2KYCqp5NwcgpPR+txqa6n8Id4VT/k1VWoLmVcmLXtT83cWrcHI92e94fDXafJXCVQtIkgT8QnisbeW5EyZIYr9XKakj8Ra9/6a/yAh/dyHOHPqxQopkBGASMf6HhShUtC4AdDGnMx00vqzW5s/ZlktAuwEfitMo+4HU= misha@user-Aspire-A315-23"
  }
}

output "instance_ip" {
  value = yandex_compute_instance.vm-build.network_interface[0].nat_ip_address
}
