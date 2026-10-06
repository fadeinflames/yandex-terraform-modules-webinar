# По умолчанию state локальный, но свой для каждого окружения (эта директория).
# Для remote state на демо: см. backend-s3.tf.example и backend-s3.hcl.example.
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
