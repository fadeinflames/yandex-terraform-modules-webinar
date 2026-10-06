variable "name_prefix" {
  description = "Префикс имён ресурсов."
  type        = string
}

variable "zone" {
  description = "Зона доступности."
  type        = string
  default     = "ru-central1-a"
}

variable "subnet_cidr" {
  description = "CIDR подсети."
  type        = string

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr: ожидается корректный IPv4 CIDR, например 10.0.1.0/24."
  }
}

variable "ingress_rules" {
  description = "Входящие TCP-правила: ключ — имя правила, значение — порт и список CIDR."
  type = map(object({
    port        = number
    cidr_blocks = list(string)
  }))
}
