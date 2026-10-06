variable "yc_token" {
  description = "OAuth/IAM-токен Yandex Cloud"
  type        = string # БОЛЬ №4: не sensitive, лежит открытым текстом в terraform.tfvars
}

variable "yc_cloud_id" {
  description = "ID облака"
  type        = string
}

variable "yc_folder_id" {
  description = "ID каталога"
  type        = string
}

variable "yc_zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-a"
}
