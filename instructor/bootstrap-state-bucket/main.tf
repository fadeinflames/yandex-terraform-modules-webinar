# ТОЛЬКО ДЛЯ ЛЕКТОРА. Создаёт бакет под remote state и сервисный аккаунт со статическим ключом.
# Запускать отдельно от окружений (курица и яйцо): у этого проекта свой ЛОКАЛЬНЫЙ state,
# в нём лежит секретный ключ, поэтому state не коммитить и не раздавать студентам.
#
#   export YC_TOKEN=$(yc iam create-token)
#   terraform init && terraform apply -var yc_cloud_id=... -var yc_folder_id=... -var bucket_name=...
#   export AWS_ACCESS_KEY_ID=$(terraform output -raw access_key)
#   export AWS_SECRET_ACCESS_KEY=$(terraform output -raw secret_key)

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.241"
    }
  }
}

variable "yc_cloud_id" {
  description = "ID облака."
  type        = string
}

variable "yc_folder_id" {
  description = "ID каталога, где живут бакет и сервисный аккаунт."
  type        = string
}

variable "bucket_name" {
  description = "Имя бакета (уникально во всём Object Storage)."
  type        = string
}

provider "yandex" {
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

resource "yandex_iam_service_account" "tfstate" {
  name        = "tfstate-demo"
  description = "Доступ к бакету со state для демо вебинара"
}

resource "yandex_resourcemanager_folder_iam_member" "tfstate_storage_editor" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.tfstate.id}"
}

resource "yandex_iam_service_account_static_access_key" "tfstate" {
  service_account_id = yandex_iam_service_account.tfstate.id
  description        = "static key for terraform state (demo)"
}

resource "yandex_storage_bucket" "tfstate" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.tfstate.access_key
  secret_key = yandex_iam_service_account_static_access_key.tfstate.secret_key

  # Версионирование: можно откатить state после ошибки.
  versioning {
    enabled = true
  }

  # Для уборки после вебинара: удаляет бакет вместе с содержимым.
  force_destroy = true

  # Права на бакет выдаются через IAM-роль, которая применяется не мгновенно.
  depends_on = [yandex_resourcemanager_folder_iam_member.tfstate_storage_editor]
}

output "access_key" {
  value     = yandex_iam_service_account_static_access_key.tfstate.access_key
  sensitive = true
}

output "secret_key" {
  value     = yandex_iam_service_account_static_access_key.tfstate.secret_key
  sensitive = true
}

output "bucket" {
  value = yandex_storage_bucket.tfstate.bucket
}
