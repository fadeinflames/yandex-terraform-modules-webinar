# Материалы для студентов

Это ваша папка: всё, что нужно до вебинара, во время него и для домашнего задания.

| Файл | Зачем |
|---|---|
| [`cheatsheet.md`](cheatsheet.md) | Шпаргалка: команды, синтаксис модулей и переменных, backend, проверки |
| [`homework/README.md`](homework/README.md) | Домашнее задание: что сделать, что сдавать, по каким критериям проверяют |
| [`homework/hints.md`](homework/hints.md) | Подсказки к ДЗ в спойлерах, без готового решения |
| [`troubleshooting.md`](troubleshooting.md) | Типичные ошибки и что с ними делать |
| [`../00-start/`](../00-start/) | Стартовый проект из одного файла: с него начинается ДЗ |
| [`../modules/`](../modules/), [`../environments/`](../environments/) | Разобранный на вебинаре пример: модули и окружения |
| [`../presentation/index.html`](../presentation/index.html) | Слайды: открываются в браузере, листаются стрелками |

## Перед вебинаром: подготовьте окружение (15–20 минут)

Вебинар идёт без практики, но домашнее задание делается в реальном облаке. Лучше подготовить всё заранее.

1. **Terraform 1.10 или новее.** Проверка: `terraform version`.
   Установка: https://developer.hashicorp.com/terraform/install. Зеркало для России: https://hashicorp-releases.yandexcloud.net/terraform/
2. **`yc` CLI** и вход в аккаунт: https://yandex.cloud/ru/docs/cli/quickstart. Проверка: `yc config list` показывает `cloud-id` и `folder-id`.
3. **Облако и каталог** с правами на создание сетей и ВМ. Если облако новое, посмотрите квоты в консоли («Квоты»): на сети по умолчанию 2 на облако, и одну уже занимает сеть `default`.
4. **SSH-ключ.** Если нет: `ssh-keygen -t ed25519`. Публичная часть лежит в `~/.ssh/id_ed25519.pub`.
5. **Зеркало провайдера.** Если `terraform init` не может скачать провайдера с registry.terraform.io, настройте зеркало Yandex Cloud: раздел «Зеркало провайдера» в `cheatsheet.md`.
6. **Токен.** Не записывайте его в файлы. Перед работой выполняйте:
   ```bash
   export YC_TOKEN=$(yc iam create-token)
   ```
   PowerShell: `$env:YC_TOKEN = (yc iam create-token)`. Токен живёт ограниченное время; при ошибке «Unauthenticated» выполните команду снова.

Проверка, что всё готово (в облаке ничего не создаёт):

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars   # подставьте cloud_id, folder_id, свой IP
terraform init
terraform validate
```

## После вебинара

1. Прочитайте [`homework/README.md`](homework/README.md) и сделайте задание: 1,5–2 часа.
2. Застряли: сначала [`troubleshooting.md`](troubleshooting.md), потом [`homework/hints.md`](homework/hints.md).
3. Перед отправкой прогоните проверки из раздела «Перед отправкой» в задании.
4. После проверки в облаке обязательно `terraform destroy` в каждом окружении: ВМ, диски и публичные адреса стоят денег, пока существуют.

## Про деньги и безопасность, коротко

- Стенд из одной ВМ стоит недорого, но за ночь набегает. Не оставляйте его «на потом».
- Никаких Managed-сервисов (БД, кластеры): для задания они не нужны и стоят дорого.
- SSH (порт 22) открывайте только со своего адреса: `curl -s https://ifconfig.me`, затем добавьте `/32`.
- Токены, ключи, `terraform.tfvars` и `*.tfstate` никогда не попадают в git. Проверка перед отправкой есть в задании.
