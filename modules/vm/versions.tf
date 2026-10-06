terraform {
  required_version = ">= 1.10.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.235.0, < 1.0.0" # ПРОВЕРИТЬ: актуальная версия на registry.terraform.io/providers/yandex-cloud/yandex
    }
  }
}
