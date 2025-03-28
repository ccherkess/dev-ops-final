variable "yc_token" {
  description = "Yandex Cloud OAuth token or IAM token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = true
}

variable "yc_zone" {
  description = "Yandex Cloud zone"
  type = string
  default = "ru-central1-a"
}

variable "yc_platform_id" {
  description = "Yandex processor type id"
  type = string
  default = "standard-v1"
}

variable "yc_boot_disk_type" {
  description = "Yandex boot disk type"
  type = string
  default = "network-ssd"
}

variable "build" {
  type    = bool
  default = false
  description = "Determines whether to create a build VM"
}

variable "run" {
  type    = bool
  default = false
  description = "Determines whether to create a run VM"
}

variable "run_count" {
  type    = number
  default = 1
  description = "Run VM counts"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

data "yandex_vpc_subnet" "default" {
  name = "default-ru-central1-a"
}
