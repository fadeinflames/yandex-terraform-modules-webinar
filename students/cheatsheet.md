# Шпаргалка: Terraform, модули, окружения, Yandex Cloud

## Рабочий цикл

```bash
terraform init             # скачать провайдера и модули, настроить backend
terraform validate         # проверить синтаксис и типы, в облако не ходит
terraform plan             # показать, что изменится; ничего не создаёт
terraform apply            # применить (спросит подтверждение)
terraform destroy          # удалить всё, что в state
terraform fmt -recursive   # отформатировать код
terraform state list       # что сейчас под управлением Terraform
terraform output           # значения outputs
terraform console          # интерактивно вычислять выражения
```

Символы в `plan`:

| Символ | Что значит |
|---|---|
| `+` | создать |
| `-` | удалить |
| `~` | изменить на месте |
| `-/+` | **удалить и создать заново** (`# forces replacement`): остановитесь и поймите, почему |
| `<=` | прочитать data-источник |

## Аутентификация без токена в файлах

```bash
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)     # можно вместо var.yc_cloud_id
export YC_FOLDER_ID=$(yc config get folder-id)
```

Провайдер читает `YC_TOKEN`, `YC_CLOUD_ID`, `YC_FOLDER_ID`, `YC_ZONE` из окружения. Блок `provider "yandex"` тогда может содержать только `zone`.

## Зеркало провайдера (если registry.terraform.io недоступен)

Файл `~/.terraformrc` (Linux, macOS) или `%APPDATA%\terraform.rc` (Windows):

```hcl
provider_installation {
  network_mirror {
    url     = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

Документация: https://yandex.cloud/ru/docs/terraform/quickstart

## Версии и lock-файл

```hcl
terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.241"     # то же, что >= 0.241, < 1.0
    }
  }
}
```

`.terraform.lock.hcl` появляется после `init` и фиксирует точную версию и хэши. **Его коммитят.**
Хэши для других ОС: `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64`.
Обновить провайдера в рамках ограничения: `terraform init -upgrade`.

## Модуль

```
modules/vm/
  main.tf        ресурсы
  variables.tf   входы
  outputs.tf     выходы
  versions.tf    required_providers (без блока provider!)
```

Вызов из окружения и связь модулей через outputs:

```hcl
module "network" {
  source      = "../../modules/network"
  name_prefix = var.name_prefix
}

module "vm" {
  source    = "../../modules/vm"
  subnet_id = module.network.subnet_id     # output одного модуля → вход другого
}
```

Адрес ресурса внутри модуля: `module.vm.yandex_compute_instance.this["web"]`.

## Переменные

```hcl
variable "servers" {
  description = "Серверы: ключ → параметры"
  type = map(object({
    cores        = optional(number, 2)    # поле необязательное, умолчание 2
    memory       = optional(number, 2)
    data_disk_gb = optional(number)       # умолчание null
  }))

  validation {
    condition     = alltrue([for s in values(var.servers) : s.memory >= 2 && s.memory <= 16])
    error_message = "memory: от 2 до 16 ГБ."
  }
}

variable "labels" {
  type     = map(string)
  default  = {}
  nullable = false      # null заменится на default
}

variable "db_password" {
  type      = string
  sensitive = true      # скрывает в выводе, но НЕ в state
}
```

Полезные проверки: `can(regex("^[a-z][-a-z0-9]*$", var.name))`, `can(cidrhost(var.cidr, 0))`, `contains(["a", "b"], var.x)`, `!contains(var.cidrs, "0.0.0.0/0")`.
В `condition` оператор `||` вычисляет оба операнда: вместо `x == null || x > 0` пишите `coalesce(x, 1) > 0`.

Откуда берутся значения: `terraform.tfvars` (в `.gitignore`), `-var name=value`, переменная окружения `TF_VAR_name`.

## Повторяющиеся блоки и ресурсы

```hcl
# dynamic: повторяющийся вложенный блок из данных
dynamic "ingress" {
  for_each = var.ingress_rules          # map
  content {
    protocol       = "TCP"
    port           = ingress.value.port
    v4_cidr_blocks = ingress.value.cidr_blocks
    description    = ingress.key
  }
}

# for_each: несколько ресурсов с ключами (вместо count с индексами)
resource "yandex_compute_instance" "this" {
  for_each = var.servers
  name     = "${var.name_prefix}-${each.key}"
}

# count: только для «включить/выключить»
resource "yandex_compute_disk" "data" {
  count = var.data_disk_gb == null ? 0 : 1
}
```

Outputs по карте ресурсов:

```hcl
output "external_ips" {
  value = { for k, vm in yandex_compute_instance.this : k => vm.network_interface[0].nat_ip_address }
}
```

## templatefile вместо heredoc

```hcl
user-data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
  server_name = "${var.name_prefix}-${each.key}"
})
```

В шаблоне подстановки пишутся как `${server_name}`; чтобы вывести `${` буквально, пишите `$${`.

## moved: рефакторинг без пересоздания

```hcl
moved {
  from = yandex_vpc_network.workshop
  to   = module.network.yandex_vpc_network.this
}
```

В `plan` ожидаем `has moved to` и `0 to add, 0 to destroy`. Появилось `-/+`: параметры не совпали с прежними, ищите строку `# forces replacement`.
`data`-источники не переносятся. Старый блок `resource` удаляем из конфигурации.

## lifecycle

```hcl
lifecycle {
  prevent_destroy       = true                       # только литерал, не переменная
  ignore_changes        = [boot_disk[0].initialize_params[0].image_id]
  create_before_destroy = true
}
```

Сторож от случайного `destroy` окружения: ресурс `terraform_data` с `prevent_destroy = true`. Снять перед плановой уборкой: `terraform state rm terraform_data.destroy_guard`.

## Remote state в Object Storage

```hcl
terraform {
  backend "s3" {
    endpoints = { s3 = "https://storage.yandexcloud.net" }
    region    = "ru-central1"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_lockfile = true    # проверьте на своём бакете
  }
}
```

```bash
export AWS_ACCESS_KEY_ID=...  AWS_SECRET_ACCESS_KEY=...       # статический ключ сервисного аккаунта
terraform init -backend-config=backend-s3.hcl                 # bucket и key в отдельном файле (в .gitignore)
terraform init -backend-config=backend-s3.hcl -migrate-state  # перенести локальный state в бакет
```

Backend-блок не принимает переменные. Свой `key` на каждое окружение. Ключи доступа никому не передавайте.

## Проверки перед коммитом

```bash
terraform fmt -check -recursive
terraform validate                          # в каждом окружении
tflint --recursive                          # линтер
gitleaks git --no-banner                    # секреты в истории git
git ls-files | grep -E 'tfvars$|tfstate'    # должно быть пусто
```

Всё это автоматизирует `pre-commit` (конфиг `.pre-commit-config.yaml` в корне репозитория): `pip install pre-commit && pre-commit install`.

## Квоты и уборка

- Сети: 2 на облако по умолчанию (сеть `default` считается). Проверьте: консоль, «Квоты».
- `yc vpc network list`, `yc compute instance list`, `yc compute disk list`: что осталось после `destroy`.
- Документация: https://yandex.cloud/ru/docs/vpc/concepts/limits, https://yandex.cloud/ru/docs/compute/concepts/limits
