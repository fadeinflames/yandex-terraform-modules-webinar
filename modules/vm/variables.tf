variable "name_prefix" {
  description = "Префикс имени ВМ и диска; полное имя ВМ: <name_prefix>-<ключ из servers>."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,30}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix: строчные латинские буквы, цифры и дефис, начинается с буквы, до 32 символов."
  }
}

variable "environment" {
  description = "Имя окружения; попадает в label environment и на страницу nginx."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment: одно из dev, stage, prod."
  }
}

variable "zone" {
  description = "Зона доступности (должна совпадать с зоной подсети)."
  type        = string
  default     = "ru-central1-a"

  validation {
    condition     = contains(["ru-central1-a", "ru-central1-b", "ru-central1-d"], var.zone)
    error_message = "zone: ожидается одна из ru-central1-a, ru-central1-b, ru-central1-d."
  }
}

variable "subnet_id" {
  description = "ID подсети, в которой создаются ВМ (output subnet_id модуля network)."
  type        = string
}

variable "security_group_ids" {
  description = "Security groups для сетевого интерфейса ВМ."
  type        = list(string)
  default     = []
}

variable "platform_id" {
  description = "Платформа ВМ."
  type        = string
  default     = "standard-v3"
}

variable "image_family" {
  description = "Семейство образа в каталоге standard-images."
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "ssh_user" {
  description = "Имя пользователя, которому добавляется SSH-ключ."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "СОДЕРЖИМОЕ публичного SSH-ключа (не путь к файлу): модуль не зависит от машины запускающего."
  type        = string

  validation {
    condition     = can(regex("^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp[0-9]+) ", var.ssh_public_key))
    error_message = "ssh_public_key: ожидается строка публичного ключа, начинающаяся с ssh-ed25519, ssh-rsa или ecdsa-sha2-..."
  }
}

variable "labels" {
  description = "Общие labels для всех ресурсов модуля (label environment добавляется автоматически)."
  type        = map(string)
  default     = {}
  nullable    = false # null превращается в значение по умолчанию {}, а не ломает merge()
}

variable "servers" {
  description = <<-EOT
    Карта серверов: ключ — суффикс имени, значение — параметры.
    data_disk_gb = null (по умолчанию) означает «без дополнительного диска».
  EOT
  type = map(object({
    cores          = optional(number, 2)
    memory         = optional(number, 2)
    core_fraction  = optional(number, 100)
    boot_disk_gb   = optional(number, 10)
    data_disk_gb   = optional(number)
    data_disk_type = optional(string, "network-hdd")
    nat            = optional(bool, true)
    labels         = optional(map(string), {})
  }))

  validation {
    condition     = length(var.servers) > 0
    error_message = "servers: нужен хотя бы один сервер."
  }

  validation {
    condition     = alltrue([for k in keys(var.servers) : can(regex("^[a-z0-9]([-a-z0-9]{0,20}[a-z0-9])?$", k))])
    error_message = "servers: ключи — строчные латинские буквы, цифры и дефис (будут частью имени ВМ)."
  }

  validation {
    condition     = alltrue([for s in values(var.servers) : s.memory >= 2 && s.memory <= 16])
    error_message = "servers: memory — от 2 до 16 ГБ (ограничение курса, не облака)."
  }

  validation {
    condition     = alltrue([for s in values(var.servers) : contains([20, 50, 100], s.core_fraction)])
    error_message = "servers: core_fraction — 20, 50 или 100. ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ: https://yandex.cloud/ru/docs/compute/concepts/performance-levels"
  }

  validation {
    # coalesce вместо `== null ||`: в HCL оператор || не вычисляется лениво, null >= 1 дал бы ошибку
    condition     = alltrue([for s in values(var.servers) : coalesce(s.data_disk_gb, 1) >= 1 && coalesce(s.data_disk_gb, 1) <= 100])
    error_message = "servers: data_disk_gb — null или от 1 до 100 ГБ."
  }
}
