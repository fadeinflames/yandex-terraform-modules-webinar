provider "yandex" {
  # token берётся из YC_TOKEN
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

module "network" {
  source = "../../modules/network"

  name_prefix = var.name_prefix
  zone        = var.yc_zone
  subnet_cidr = var.subnet_cidr

  ingress_rules = {
    ssh   = { port = 22, cidr_blocks = var.ssh_allowed_cidrs }
    http  = { port = 80, cidr_blocks = ["0.0.0.0/0"] }
    https = { port = 443, cidr_blocks = ["0.0.0.0/0"] }
  }
}

module "vm" {
  source = "../../modules/vm"

  name               = "${var.name_prefix}-web"
  zone               = var.yc_zone
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.network.security_group_id]
  cores              = var.cores
  memory             = var.memory
  data_disk_gb       = var.data_disk_gb
  ssh_public_key     = trimspace(file(pathexpand(var.ssh_public_key_path)))
  labels             = { environment = "dev", owner = var.owner, task = "homework" }
}
