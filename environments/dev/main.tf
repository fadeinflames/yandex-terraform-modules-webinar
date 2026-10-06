locals {
  environment = "dev"
}

provider "yandex" {
  # token не указываем: провайдер берёт его из переменной окружения YC_TOKEN
  # (или используйте сервисный аккаунт: YC_SERVICE_ACCOUNT_KEY_FILE).
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Версии модулей: сейчас модули лежат рядом (локальный путь), поэтому pinning не нужен.
# Когда модули переедут в отдельный репозиторий, фиксируем тег:
#   source = "git::https://github.com/<org>/terraform-yc-modules.git//modules/network?ref=v1.0.0"

module "network" {
  source = "../../modules/network"

  name_prefix = var.name_prefix
  zone        = var.yc_zone
  subnet_cidr = var.subnet_cidr

  # БЫЛО: три копипастных блока ingress. СТАЛО: данные, которые читает dynamic в модуле.
  ingress_rules = {
    ssh = {
      port        = 22
      cidr_blocks = var.ssh_allowed_cidrs
      description = "SSH"
    }
    http = {
      port        = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    }
    https = {
      port        = 443
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  }
}

module "vm" {
  source = "../../modules/vm"

  name_prefix        = var.name_prefix
  environment        = local.environment
  zone               = var.yc_zone
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.network.security_group_id]

  # БЫЛО: file("~/.ssh/id_rsa.pub") внутри ресурса. СТАЛО: путь — параметр окружения,
  # модуль получает уже прочитанное содержимое и от машины не зависит.
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))

  labels  = { owner = var.owner, task = "demo" }
  servers = var.servers
}
