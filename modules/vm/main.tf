# БЫЛО (00-start): data.yandex_compute_image.ubuntu, yandex_compute_disk.data,
#                  yandex_compute_instance.web (один сервер, всё захардкожено).
# СТАЛО: те же ресурсы в модуле; серверов может быть несколько (for_each).

data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

locals {
  labels = merge(var.labels, { environment = var.environment })

  # Дополнительный диск есть только у серверов с заданным data_disk_gb.
  data_disks = { for name, s in var.servers : name => s if s.data_disk_gb != null }
}

resource "yandex_compute_disk" "data" {
  for_each = local.data_disks

  name = "${var.name_prefix}-${each.key}-data"
  zone = var.zone
  type = each.value.data_disk_type
  size = each.value.data_disk_gb
}

resource "yandex_compute_instance" "this" {
  for_each = var.servers

  name                      = "${var.name_prefix}-${each.key}"
  platform_id               = var.platform_id
  zone                      = var.zone
  allow_stopping_for_update = true
  labels                    = merge(local.labels, each.value.labels)

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = each.value.boot_disk_gb
    }
  }

  dynamic "secondary_disk" {
    for_each = each.value.data_disk_gb != null ? [yandex_compute_disk.data[each.key].id] : []

    content {
      disk_id = secondary_disk.value
    }
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = each.value.nat
    security_group_ids = var.security_group_ids
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"

    # БЫЛО: heredoc с cloud-init прямо в ресурсе.
    # СТАЛО: файл-шаблон + templatefile(); параметры видны в одном месте.
    user-data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      server_name = "${var.name_prefix}-${each.key}"
      environment = var.environment
    })
  }

  lifecycle {
    # Новая версия образа в семействе не должна пересоздавать ВМ.
    # prevent_destroy здесь НЕТ: lifecycle принимает только литералы, параметром его не сделать.
    # Защита prod от случайного destroy живёт на уровне окружения (environments/prod/main.tf).
    ignore_changes = [boot_disk[0].initialize_params[0].image_id]
  }
}
