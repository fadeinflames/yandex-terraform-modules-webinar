# Типичные ошибки и диагностика

Формат: **симптом → вероятная причина → что делать**. Места, где формулировка ошибки зависит от версии Terraform или провайдера, помечены «ПРОВЕРИТЬ»:
точный текст в вашей версии может отличаться, ориентируйтесь на смысл.

## Квоты

| Симптом | Причина | Что делать |
|---|---|---|
| `Quota limit vpc.networks.count exceeded` (ПРОВЕРИТЬ текст) при `apply` сети | Квота «Networks» исчерпана (по документации 2 на облако), в неё входит сеть `default` и развёрнутый стенд из `00-start` | `yc vpc network list`; `terraform destroy` в старой папке; удалить неиспользуемую `default`; применять окружения по очереди; запросить увеличение квоты. Документация: https://yandex.cloud/ru/docs/vpc/concepts/limits |
| Ошибка квоты на vCPU/RAM/диски/публичные адреса | Лимиты Compute/VPC на облако | Консоль «Квоты»; уменьшить размеры в `terraform.tfvars`; https://yandex.cloud/ru/docs/compute/concepts/limits |

## Установка и провайдер

| Симптом | Причина | Что делать |
|---|---|---|
| `terraform init` долго висит или `Failed to query available provider packages` | registry.terraform.io недоступен из вашей сети | Настроить зеркало Yandex в `.terraformrc` (`network_mirror`), документация: https://yandex.cloud/ru/docs/terraform/quickstart |
| `locked provider ... does not match configured version constraint` | Поменяли `version` в `versions.tf`, а lock-файл старый | `terraform init -upgrade`, проверить diff `.terraform.lock.hcl`, закоммитить |
| `Error: Failed to install provider ... checksum` / хэши платформы | Lock создан на другой ОС или через зеркало (в нём только часть хэшей) | `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64` (ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ) |
| `Unsupported Terraform Core version` | Ваш Terraform старше `required_version` (>= 1.10) | Обновить Terraform |
| `Module not installed` / `Module source has changed` | Добавили или переименовали модуль | `terraform init` |
| `Unsupported argument` в вызове модуля | Передаёте аргумент, которого нет в `variable` модуля | Сверить имена в `variables.tf` модуля |

## Права и аутентификация

| Симптом | Причина | Что делать |
|---|---|---|
| `Permission denied` / `PermissionDenied` на создание сети, ВМ | У токена/аккаунта нет роли в каталоге | Нужны роли на каталог, например `vpc.admin` и `compute.editor` (ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ: https://yandex.cloud/ru/docs/iam/concepts/access-control/roles) |
| `Unauthenticated` / `token is expired` | Токен IAM живёт ограниченное время | `export YC_TOKEN=$(yc iam create-token)` и повторить |
| `YC_TOKEN` не подхватывается | В другом терминале/сессии не экспортирован; в блоке provider остался `token = ...` | Проверить `echo $YC_TOKEN` (в PowerShell `$env:YC_TOKEN`); убрать `token` из provider |

## Remote state (backend)

| Симптом | Причина | Что делать |
|---|---|---|
| `Backend configuration changed` | Изменили backend-блок | `terraform init -reconfigure` (без переноса) или `terraform init -migrate-state` (с переносом state) |
| `Error: ... NoSuchBucket` | Неверное имя бакета, нет доступа к нему или не тот каталог | Проверить `backend-s3.hcl`, `yc storage bucket list` |
| `InvalidAccessKeyId` / `SignatureDoesNotMatch` / `AccessDenied` | Не заданы или неверны `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`; у сервисного аккаунта нет роли на бакет | Экспортировать статический ключ **сервисного аккаунта**; роль `storage.editor` на каталог/бакет |
| Ошибки валидации региона/аккаунта/checksum при init | Не заданы `skip_*` флаги для S3-совместимого хранилища | Скопировать флаги из `backend-s3.tf.example` (ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ: https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-state-storage) |
| `Error acquiring the state lock` | Блокировку держит другой запуск (или упавший) | Дождаться; если процесс умер: `terraform force-unlock <ID>` (только убедившись, что никто не работает) |
| `use_lockfile` не создаёт блокировку / не поддерживается | Нативный lock-файл в Object Storage не подтверждён документацией | ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ и на своём бакете; запасной вариант: YDB + `dynamodb_table` (https://yandex.cloud/ru/docs/ydb/tutorials/terraform-state-lock) |

## SSH-ключи и пути

| Симптом | Причина | Что делать |
|---|---|---|
| `no file exists at ~/.ssh/id_rsa.pub` (`Invalid value for "path" parameter`) | Ключа с таким именем нет (у вас `id_ed25519.pub`), либо путь для другой ОС | Указать свой путь в `ssh_public_key_path` в `terraform.tfvars`; `ls ~/.ssh`; не правьте код модуля. Раньше это «лечили» симлинком; теперь путь — параметр |
| `Invalid value for variable ... ssh_public_key` | Передан не публичный ключ (например приватный или путь) | Нужна одна строка `ssh-ed25519 AAAA...` из `*.pub` |
| `Permission denied (publickey)` при `ssh` | Не тот ключ, SG не пропускает ваш IP | Проверить `ssh_allowed_cidrs` (ваш адрес `/32` изменился: `curl -s https://ifconfig.me`), пользователь `ubuntu`, `ssh -i <приватный ключ>` |
| SSH висит (timeout) | Не открыт 22 для вашего IP или у ВМ нет публичного адреса (`nat = false`) | Проверить правила SG и `nat` |

## moved, replace и «опасный» plan

| Симптом | Причина | Что делать |
|---|---|---|
| В plan появилось `-/+` (`# forces replacement`) для ресурса, который должен был переехать | Параметры в модуле не совпали с прежними (имя, зона, CIDR, размер диска, образ) | Найти поле с `# forces replacement` и выровнять значение с прежним; **не делайте `apply`**, пока в plan есть `-/+` для существующих ресурсов |
| plan показывает `+` для нового адреса и `-` для старого, а `moved` не сработал | Нет блока `moved` или неверный адрес `to` (забыли `["web"]` для `for_each`) | Проверить адреса: `terraform state list` и сообщение `has moved to` в plan |
| `Moved object still exists` | Старый адрес всё ещё есть в конфигурации (ресурс остался в `main.tf`) | Удалить старый блок `resource`, оставить только `moved` |
| В plan только `~` на ВМ/SG | Изменение «на месте» (имена, metadata, правила) | Нормально, если вы понимаете причину; читайте diff построчно |
| Хочу вернуть ресурс «на старое место» | Перенос в state уже выполнен | Добавьте обратный `moved` либо `terraform state mv` |
| `data` не переехал | `data`-источники не переносятся блоком `moved` | Это нормально: он прочитается заново |

## Прочее

| Симптом | Причина | Что делать |
|---|---|---|
| `Error: Invalid value for variable` с вашим сообщением | Сработала `validation` | Исправить значение по подсказке `error_message` |
| `terraform destroy` в prod: `Instance cannot be destroyed` (`prevent_destroy`) | Сработал сторож `terraform_data.destroy_guard` (так задумано) | `terraform state rm terraform_data.destroy_guard`, затем `terraform destroy` (формулировку ошибки ПРОВЕРИТЬ в своей версии) |
| `terraform destroy` не удаляет диск | Диск прикреплён к ВМ, порядок удаления | Повторить `destroy`; смотреть, не остались ли ВМ вне Terraform |
| После `apply` nginx не открывается | cloud-init ещё выполняется (1–3 минуты); не открыт порт 80 | Подождать; проверить SG; на ВМ: `cloud-init status`, `sudo journalctl -u nginx` |
| Что-то поломалось и непонятно | — | Прочитать ошибку целиком (она подсказывает файл и строку); `terraform validate`; `TF_LOG=INFO terraform plan` (не публиковать лог: в нём могут быть данные) |
