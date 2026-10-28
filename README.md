# yandex-terraform-modules-webinar

Воркшоп «Terraform: модули, окружения, best practices» (Yandex Cloud). Репозиторий самодостаточен: демо и домашнее задание запускаются из него.

Стенд один на всём пути: сеть + security group + ВМ с nginx + диск. Он проходит путь:
плоский `main.tf` (`00-start/`) → модули `network` и `vm` → окружения `dev` и `prod` из одних модулей → remote state → защитные практики.

## Структура

```
.
├── 00-start/               плоский стартовый проект: main.tf, variables.tf, outputs.tf (исходная точка рефакторинга)
├── modules/
│   ├── network/            сеть + подсеть + security group (dynamic ingress)
│   └── vm/                 ВМ (for_each) + диск данных + cloud-init (templatefile)
├── environments/
│   ├── dev/                свой state и tfvars; moved.tf переносит стенд из 00-start без пересоздания
│   └── prod/               те же модули, другие значения; сторож от случайного destroy
├── presentation/           index.html (презентация, 18 слайдов) и slides.md (структура слайдов)
├── students/               материалы студентов
│   ├── README.md           с чего начать, подготовка окружения
│   ├── cheatsheet.md       шпаргалка по командам и синтаксису
│   ├── troubleshooting.md  типичные ошибки и диагностика
│   └── homework/           README.md (задание) и hints.md (подсказки)
├── .pre-commit-config.yaml
├── .tflint.hcl
└── .gitignore              lock-файл НЕ игнорируется
```

Материалы лектора (`instructor/`) в `main` не входят.

## Требования

- Terraform >= 1.10 (нужен для `use_lockfile`), провайдер `yandex-cloud/yandex ~> 0.241` (ПРОВЕРИТЬ актуальную версию в реестре).
- Аккаунт Yandex Cloud с каталогом, `yc` CLI, SSH-ключ (`~/.ssh/id_ed25519.pub`).
- Аутентификация без токена в коде: `export YC_TOKEN=$(yc iam create-token)` (PowerShell: `$env:YC_TOKEN = (yc iam create-token)`).

## Что проверено

Код прогнан на Terraform 1.16.5 с провайдером `yandex-cloud/yandex` 0.241.0 (2026-10-28):
`terraform fmt -check`, `init` и `validate` во всех окружениях, `tflint` 0.65 (ruleset terraform), `gitleaks` 8.30.
`00-start/` намеренно содержит ошибки (нет версий, старый синтаксис `.0`, путь к ключу в коде) и исключён из линтеров в `.pre-commit-config.yaml`.
`terraform plan` и `apply` требуют реального облака: прогоните их на своём каталоге перед вебинаром.

## Быстрый старт (окружение dev)

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars    # подставить cloud_id, folder_id, свой IP для SSH
export YC_TOKEN=$(yc iam create-token)
terraform init
terraform plan
terraform apply
terraform destroy                               # когда закончили
```

## Lock-файл

`.terraform.lock.hcl` **коммитим** (по одному на окружение). Он фиксирует точную версию провайдера и её хэши.
Для команды на разных ОС: `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64`.

## Квоты и стоимость

В документации квота «Networks» указана на облако, по умолчанию 2 (https://yandex.cloud/ru/docs/vpc/concepts/limits);
в неё входит сеть `default`. Для dev и prod нужны две сети. ПРОВЕРИТЬ свои квоты в консоли.
Не забывайте `terraform destroy`: ВМ, диски и публичные адреса тарифицируются.

## Remote state (демо лектора)

См. `environments/dev/backend-s3.tf.example`. Лектор показывает remote state на заранее подготовленном бакете.
Общие ключи студентам не раздаются. Студенческий вариант со своим бакетом: задание ★4 в `students/homework/`.

Запасной вариант блокировки, если `use_lockfile` не подтвердится на вашем бакете: YDB + `dynamodb_table`
(https://yandex.cloud/ru/docs/ydb/tutorials/terraform-state-lock; в документации блокировка через Document API объявлена устаревшей с Terraform 1.11).

## Плоский проект (`00-start`) → после рефакторинга

| `00-start` | Результат |
|---|---|
| Всё в одном `main.tf` | Модули `network`, `vm` + окружения |
| Три блока `ingress` | `dynamic "ingress"` по `map` правил |
| `.terraform.lock.hcl` в `.gitignore` | Lock-файл коммитим |
| Нет `required_version` и версии провайдера | `required_version`, `version = "~> 0.241"` |
| Токен в `terraform.tfvars` (`variable "yc_token"`) | `YC_TOKEN` из окружения, переменной нет |
| SSH с `0.0.0.0/0` | `ssh_allowed_cidrs`, в prod `0.0.0.0/0` запрещён валидацией |
| `file("~/.ssh/id_rsa.pub")` в ресурсе | Путь — параметр окружения, в модуль уходит содержимое ключа |
| `network_interface.0.…` | `network_interface[0].…` |
| Локальный общий state | Раздельный state на окружение, remote state в Object Storage |
| heredoc cloud-init | `templatefile()` |
