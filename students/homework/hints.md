# Подсказки к домашнему заданию

Полного решения здесь нет, только направления и скелеты. Раскрывайте по одной подсказке, сначала попробуйте сами.

<details>
<summary>Подсказка 1. С чего начать: порядок работы</summary>

1. Создайте новый репозиторий, положите туда `00-start/` из репозитория вебинара (исходный проект) и каталоги `modules/network`, `modules/vm`, `environments/dev`, `environments/prod`.
2. Сначала соберите **dev** целиком. Prod появится как копия dev с другими значениями.
3. Сначала модуль `network` (проще), потом `vm`.
4. После каждого шага: `terraform fmt`, `terraform validate`.
5. Если вы разворачивали `00-start`, уничтожьте его (`terraform destroy`) до первого `apply` в новом проекте, иначе упрётесь в квоту сетей.
</details>

<details>
<summary>Подсказка 2. Как понять, что выносить в переменные модуля</summary>

Всё, что отличается между dev и prod или зависит от вашей машины: имя/префикс, зона, CIDR, число vCPU, память, размер диска, SSH-ключ.
Что не меняется между окружениями, можно оставить внутри модуля константой (например, `platform_id = "standard-v3"` или egress «разрешить всё»).

Хороший тест: откройте `main.tf` модуля. Если там есть строка-литерал, которую вы бы поменяли для prod, это должна быть переменная.
</details>

<details>
<summary>Подсказка 3. Скелет модуля и вызова</summary>

```hcl
# modules/network/variables.tf
variable "name_prefix" {
  description = "..."
  type        = string
}

# environments/dev/main.tf
module "network" {
  source = "../../modules/network"

  name_prefix = var.name_prefix
  # ...остальные параметры
}

# значение из одного модуля в другой передаём через outputs:
#   modules/network/outputs.tf -> output "subnet_id" { value = yandex_vpc_subnet.this.id }
#   environments/dev/main.tf   -> subnet_id = module.network.subnet_id
```

Каждому модулю нужен свой `versions.tf` с `required_providers` (источник `yandex-cloud/yandex`).
Блок `provider "yandex"` в модулях **не пишем**: провайдер настраивается в окружении.
</details>

<details>
<summary>Подсказка 4. dynamic для правил security group</summary>

Правила удобно описать как `map(object(...))` и пробежаться по нему:

```hcl
variable "ingress_rules" {
  type = map(object({
    port        = number
    cidr_blocks = list(string)
  }))
}

# в ресурсе security group:
dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    protocol       = "TCP"
    port           = ingress.value.port
    v4_cidr_blocks = ingress.value.cidr_blocks
    description    = ingress.key
  }
}
```

Внутри `content` обращаются к `ingress.key` и `ingress.value` (имя берётся от имени блока).
</details>

<details>
<summary>Подсказка 5. validation</summary>

```hcl
variable "memory" {
  type = number

  validation {
    condition     = var.memory >= 2 && var.memory <= 16
    error_message = "memory: от 2 до 16 ГБ."
  }
}
```

Проверка формата: `can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.name))`, проверка CIDR: `can(cidrhost(var.cidr, 0))`.
Запретить `0.0.0.0/0` в prod: `!contains(var.ssh_allowed_cidrs, "0.0.0.0/0")`.
Сделайте так, чтобы нарушить правило и увидеть собственное сообщение об ошибке: это и есть проверка.
</details>

<details>
<summary>Подсказка 6. Токен и SSH-ключ без хардкода</summary>

- Токен: `export YC_TOKEN=$(yc iam create-token)`; в блоке `provider "yandex"` токен **не указываем** вовсе.
  PowerShell: `$env:YC_TOKEN = (yc iam create-token)`.
- Путь к ключу: параметр окружения (`ssh_public_key_path`), а в модуль передавайте **содержимое** ключа:
  `trimspace(file(pathexpand(var.ssh_public_key_path)))`.
  Если ключ называется иначе (`id_rsa.pub`, `id_ed25519.pub`), меняйте значение в `terraform.tfvars`, а не в коде.
- Свой адрес для SSH: `curl -s https://ifconfig.me`, затем добавьте `/32`.
</details>

<details>
<summary>Подсказка 7. Lock-файл и версии</summary>

Проверьте `.gitignore`: строки `.terraform.lock.hcl` там быть не должно (её часто добавляют по привычке): **удалите её**, если она есть.
В `versions.tf` окружения:

```hcl
terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.235" # посмотрите актуальную версию в реестре Terraform
    }
  }
}
```

После `terraform init` появится `.terraform.lock.hcl`. Если вы работаете на нескольких ОС, добавьте хэши платформ:
`terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64`
(ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ: https://developer.hashicorp.com/terraform/cli/commands/providers/lock).
</details>

<details>
<summary>Подсказка 8. Как сделать dev и prod «одним кодом» и не копипастить лишнее</summary>

Различия между окружениями живут в `terraform.tfvars` (размеры, префикс, CIDR) и в паре параметров `main.tf` (например, правила ingress).
`main.tf` двух окружений будут очень похожи, и это нормально: каждое окружение — отдельный корневой модуль со своим state.
Дублируется только «склейка» (вызовы модулей), а не логика.
Не пытайтесь «объединить» окружения через `count`/workspaces в одной директории: тогда пропадёт раздельный state, а он нужен.
</details>

<details>
<summary>Подсказка 9 (★3). moved: перенос без пересоздания</summary>

Формат:

```hcl
moved {
  from = yandex_vpc_network.workshop          # старый адрес в плоском проекте
  to   = module.network.yandex_vpc_network.this # новый адрес внутри модуля
}
```

Порядок:
1. Скопируйте старый `terraform.tfstate` в директорию окружения, куда переезжаете.
2. Добавьте блоки `moved` для сети, подсети, security group, диска, ВМ.
3. `terraform plan`: должны быть строки `has moved to`, и **ни одного** `-/+` и `+` для этих ресурсов.
   Допустимы `~` (например, переименовались, изменились метаданные): это изменение «на месте».
   Если видите `-/+` (replace), значит параметры не совпали с прежними. Сверьте имя, зону, CIDR, размер диска.
4. Адрес ресурса после `for_each` выглядит как `module.vm.yandex_compute_instance.this["web"]`.
5. `data`-источники переносить не нужно: они читаются заново.
</details>

<details>
<summary>Подсказка 10 (★1, ★2). for_each и templatefile</summary>

```hcl
resource "yandex_compute_instance" "this" {
  for_each = var.servers        # map: ключ -> параметры
  name     = "${var.name_prefix}-${each.key}"
  # ...
}

# cloud-init:
user-data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
  server_name = "${var.name_prefix}-${each.key}"
})
```

Ссылка на ресурс с `for_each` — `yandex_compute_instance.this["web"]`, а в outputs удобно собрать map через `for`-выражение.
Хотите перейти с одиночного ресурса на `for_each` и не пересоздать ВМ: блок `moved` из `...this` в `...this["web"]`.
</details>

<details>
<summary>Подсказка 11 (★4). Свой бакет под remote state</summary>

Нужно: сервисный аккаунт с ролью на бакет (например `storage.editor`), статический ключ доступа, бакет с включённым версионированием.
Бакет и ключи создайте **отдельным** маленьким проектом (не в тех окружениях, чьим state он будет хранить: курица и яйцо).
Backend-блок не принимает переменные: `bucket` и `key` передайте через `terraform init -backend-config=backend-s3.hcl`,
а ключи через `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`.
Пример backend для Object Storage: `environments/dev/backend-s3.tf.example` в репозитории вебинара.
Миграция state: `terraform init -migrate-state -backend-config=backend-s3.hcl`.
Не коммитьте `backend-s3.hcl` и ключи. Эти ключи только ваши, не делитесь ими.
Блокировка: `use_lockfile = true`. ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ и на своём бакете (см. комментарии в примере).
</details>

<details>
<summary>Подсказка 12 (★5). pre-commit</summary>

`pip install pre-commit`, затем возьмите `.pre-commit-config.yaml` из репозитория вебинара, оставьте хуки
`terraform_fmt`, `terraform_validate`, `terraform_tflint` (нужны установленные `terraform` и `tflint`) и выполните
`pre-commit install` и `pre-commit run -a`.
</details>

<details>
<summary>Подсказка 13. Если что-то не работает</summary>

- `Error: Invalid value for variable` — сработала ваша `validation`: читайте `error_message`.
- `Quota exceeded` / `network quota` — см. раздел «Квоты» в README задания.
- `Unsupported argument` в модуле — вы передаёте в модуль аргумент, которого нет в его `variable`.
- `Module not installed` — после добавления модуля нужен `terraform init`.
- `plan` хочет пересоздать ВМ (`-/+`) — смотрите, какое поле помечено `# forces replacement`.
- `terraform init` не может скачать провайдера — зеркало Yandex, см. `.terraformrc` в документации
  https://yandex.cloud/ru/docs/terraform/quickstart.
</details>
