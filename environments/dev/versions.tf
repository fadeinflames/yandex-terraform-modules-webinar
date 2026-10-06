terraform {
  # БЫЛО: ни required_version, ни версии провайдера. СТАЛО: диапазон здесь,
  # точная версия фиксируется закоммиченным .terraform.lock.hcl.
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.235" # >= 0.235, < 1.0. ПРОВЕРИТЬ: актуальная версия на registry.terraform.io/providers/yandex-cloud/yandex
    }
  }
}
