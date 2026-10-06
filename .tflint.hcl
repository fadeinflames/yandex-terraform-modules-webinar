config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ: правила terraform-ruleset
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/README.md
# Отдельного плагина tflint для провайдера yandex-cloud/yandex не подключаем.
