variable "name" {
  description = "Имя ВМ (диск получит суффикс -data)."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,40}[a-z0-9])?$", var.name))
    error_message = "name: строчные латинские буквы, цифры и дефис, начинается с буквы."
  }
}

variable "zone" {
  description = "Зона доступности."
  type        = string
  default     = "ru-central1-a"
}

variable "subnet_id" {
  description = "ID подсети."
  type        = string
}

variable "security_group_ids" {
  description = "Security groups интерфейса."
  type        = list(string)
  default     = []
}

variable "cores" {
  description = "Число vCPU."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Память, ГБ."
  type        = number
  default     = 2

  validation {
    condition     = var.memory >= 2 && var.memory <= 16
    error_message = "memory: от 2 до 16 ГБ."
  }
}

variable "boot_disk_gb" {
  description = "Размер загрузочного диска, ГБ."
  type        = number
  default     = 10
}

variable "data_disk_gb" {
  description = "Размер дополнительного диска, ГБ."
  type        = number
  default     = 5
}

variable "ssh_public_key" {
  description = "Содержимое публичного SSH-ключа."
  type        = string
}

variable "labels" {
  description = "Labels ВМ."
  type        = map(string)
  default     = {}
}
