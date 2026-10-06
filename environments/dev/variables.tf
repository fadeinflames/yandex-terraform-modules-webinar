# БЫЛО: yc_token, yc_cloud_id, yc_folder_id, yc_zone. СТАЛО: токена среди переменных нет
# (берётся из окружения: YC_TOKEN), остальное — параметры окружения.

variable "yc_cloud_id" {
  description = "ID облака."
  type        = string
}

variable "yc_folder_id" {
  description = "ID каталога для этого окружения."
  type        = string
}

variable "yc_zone" {
  description = "Зона доступности."
  type        = string
  default     = "ru-central1-a"
}

variable "name_prefix" {
  description = "Префикс имён ресурсов окружения."
  type        = string
  default     = "workshop"
}

variable "subnet_cidr" {
  description = "CIDR подсети окружения."
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_allowed_cidrs" {
  description = "С каких адресов разрешён SSH (CIDR). Свой адрес: curl -s https://ifconfig.me, затем /32."
  type        = list(string)

  validation {
    condition     = length(var.ssh_allowed_cidrs) > 0
    error_message = "ssh_allowed_cidrs: нужен хотя бы один CIDR."
  }
}

variable "ssh_public_key_path" {
  description = "Путь к ПУБЛИЧНОМУ SSH-ключу на машине запускающего. Содержимое ключа передаётся в модуль vm."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "owner" {
  description = "Владелец стенда (label owner)."
  type        = string
}

variable "servers" {
  description = "Серверы окружения. Тип и проверки описаны в модуле vm, здесь это просто транзит."
  type        = any
}
