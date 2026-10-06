variable "name_prefix" {
  description = "Префикс имён сети, подсети и security group (например, workshop или workshop-prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,40}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix: строчные латинские буквы, цифры и дефис, начинается с буквы, до 42 символов."
  }
}

variable "zone" {
  description = "Зона доступности для подсети."
  type        = string
  default     = "ru-central1-a"

  validation {
    condition     = contains(["ru-central1-a", "ru-central1-b", "ru-central1-d"], var.zone)
    error_message = "zone: ожидается одна из ru-central1-a, ru-central1-b, ru-central1-d. ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ: https://yandex.cloud/ru/docs/overview/concepts/geo-scope"
  }
}

variable "subnet_cidr" {
  description = "CIDR подсети, например 10.0.1.0/24."
  type        = string

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr: ожидается корректный IPv4 CIDR, например 10.0.1.0/24."
  }
}

variable "ingress_rules" {
  description = <<-EOT
    Входящие правила security group: ключ — короткое имя правила (ssh, http, https),
    значение — порт, список CIDR, протокол и описание.
  EOT
  type = map(object({
    port        = number
    cidr_blocks = list(string)
    protocol    = optional(string, "TCP")
    description = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.ingress_rules) : r.port >= 1 && r.port <= 65535])
    error_message = "ingress_rules: порт должен быть в диапазоне 1–65535."
  }

  validation {
    condition     = alltrue([for r in values(var.ingress_rules) : contains(["TCP", "UDP", "ICMP", "ANY"], r.protocol)])
    error_message = "ingress_rules: protocol — одно из TCP, UDP, ICMP, ANY."
  }

  validation {
    condition = alltrue(flatten([
      for r in values(var.ingress_rules) : [for c in r.cidr_blocks : can(cidrhost(c, 0))]
    ]))
    error_message = "ingress_rules: каждый элемент cidr_blocks должен быть корректным IPv4 CIDR."
  }
}
