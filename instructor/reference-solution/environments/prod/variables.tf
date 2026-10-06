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
  default     = "hw-prod"
}

variable "subnet_cidr" {
  description = "CIDR подсети."
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_allowed_cidrs" {
  description = "Откуда разрешён SSH (в prod не 0.0.0.0/0)."
  type        = list(string)

  validation {
    condition     = !contains(var.ssh_allowed_cidrs, "0.0.0.0/0")
    error_message = "В prod SSH нельзя открывать всему интернету."
  }
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
  default     = 4
}

variable "data_disk_gb" {
  description = "Диск данных, ГБ."
  type        = number
  default     = 10
}
