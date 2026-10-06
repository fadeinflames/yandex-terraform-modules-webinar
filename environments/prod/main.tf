locals {
  environment = "prod"
}

provider "yandex" {
  # token не указываем: провайдер берёт его из переменной окружения YC_TOKEN
  # (или используйте сервисный аккаунт: YC_SERVICE_ACCOUNT_KEY_FILE).
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Сторож от случайного `terraform destroy` в prod.
# lifecycle принимает только литералы, поэтому prevent_destroy нельзя передать в модуль параметром.
# Любой запланированный destroy этого объекта обрывает ВЕСЬ `terraform destroy` с ошибкой.
# Защита от `destroy` не защищает от правки кода (удалили ресурс из конфигурации, и всё пройдёт).
# Для штатной уборки: terraform state rm terraform_data.destroy_guard && terraform destroy
resource "terraform_data" "destroy_guard" {
  lifecycle {
    prevent_destroy = true
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix = var.name_prefix
  zone        = var.yc_zone
  subnet_cidr = var.subnet_cidr

  ingress_rules = {
    ssh = {
      port        = 22
      cidr_blocks = var.ssh_allowed_cidrs
      description = "SSH from allowed CIDRs only"
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
  ssh_public_key     = trimspace(file(pathexpand(var.ssh_public_key_path)))

  labels  = { owner = var.owner, task = "demo" }
  servers = var.servers
}
