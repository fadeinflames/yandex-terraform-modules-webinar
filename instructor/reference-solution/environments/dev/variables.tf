variable "yc_cloud_id" {
  description = "ID облака."
  type        = string
}

variable "yc_folder_id" {
  description = "ID каталога."
  type        = string
}

variable "yc_zone" {
  description = "Зона доступности."
  type        = string
  default     = "ru-central1-a"
}

variable "name_prefix" {
  description = "Префикс имён."
  type        = string
  default     = "hw-dev"
}

variable "subnet_cidr" {
  description = "CIDR подсети."
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_allowed_cidrs" {
  description = "Откуда разрешён SSH."
  type        = list(string)
}

variable "ssh_public_key_path" {
  description = "Путь к публичному ключу."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "owner" {
  description = "Владелец (label)."
  type        = string
}

variable "cores" {
  description = "vCPU."
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM, ГБ."
  type        = number
  default     = 2
}

variable "data_disk_gb" {
  description = "Диск данных, ГБ."
  type        = number
  default     = 5
}
