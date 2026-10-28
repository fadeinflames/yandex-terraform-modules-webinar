terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.241" # >= 0.241, < 1.0. проверено 2026-10-28; точную версию фиксирует .terraform.lock.hcl
    }
  }
}
