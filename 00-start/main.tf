# 00-start: плоский стартовый проект. Это исходная точка рефакторинга: работает, но в нём намеренно
# оставлены слабые места (комментарии «БОЛЬ №N»). За вебинар мы их исправим.

terraform {
  # БОЛЬ №3: нет required_version и ограничения версии провайдера
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.yc_token # БОЛЬ №4: токен приходит из terraform.tfvars
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# --- Сеть --------------------------------------------------------------

resource "yandex_vpc_network" "workshop" {
  name = "workshop-network" # БОЛЬ №1: всё захардкожено
}

resource "yandex_vpc_subnet" "workshop" {
  name           = "workshop-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.workshop.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_security_group" "web_sg" {
  name       = "workshop-web-sg"
  network_id = yandex_vpc_network.workshop.id

  # БОЛЬ №2: три почти одинаковых блока
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"] # БОЛЬ №5: SSH открыт всему интернету
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# --- Образ, диск, ВМ -----------------------------------------------------

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "data" {
  name = "workshop-web-data"
  zone = "ru-central1-a"
  type = "network-hdd"
  size = 5
}

resource "yandex_compute_instance" "web" {
  name                      = "workshop-web"
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"
  allow_stopping_for_update = true

  labels = {
    environment = "dev"
    owner       = "lecturer"
    task        = "demo"
  }

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  secondary_disk {
    disk_id = yandex_compute_disk.data.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.workshop.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    # БОЛЬ №6: путь к ключу зашит в код и зависит от машины
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"

    # БОЛЬ №1: cloud-init heredoc прямо в main.tf
    user-data = <<-EOT
      #cloud-config
      package_update: true
      packages:
        - nginx
      runcmd:
        - systemctl enable nginx
        - systemctl start nginx
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}
