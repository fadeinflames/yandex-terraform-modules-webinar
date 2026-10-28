# Чек-лист подготовки лектора и уборка

## За 3–5 дней

- [ ] **Облако и каталоги.** Отдельное облако (или каталоги) под демо. Два каталога `workshop-dev` и `workshop-prod`
      показывают «folder_id на окружение» (изоляция прав и биллинга). Если каталог один — тоже ок, ссылайтесь на слайд про изоляцию.
- [ ] **Квоты.** По документации «Networks» = 2 **на облако** (https://yandex.cloud/ru/docs/vpc/concepts/limits):
      ПРОВЕРИТЬ в консоли «Квоты» своего облака. Автосозданная сеть `default` в каждом каталоге **входит в квоту**.
      Для демо нужны 2 сети (dev + prod): удалите ненужные `default` (`yc vpc network list`, убедитесь, что ими никто не пользуется)
      или запросите увеличение квоты заранее (заявка не мгновенная).
      Также проверьте квоты Compute (vCPU, RAM, диски; ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ: https://yandex.cloud/ru/docs/compute/concepts/limits;
      в документации указано, что с 12.10.2026 девять квот переходят с регионального на зонное распределение: проверьте актуальные значения для `ru-central1-a`)
      и число публичных IP (dev 1 + prod 2).
- [ ] **Версии.** Terraform >= 1.10 (на момент подготовки актуален 1.16.x, ПРОВЕРИТЬ на releases.hashicorp.com),
      провайдер `yandex-cloud/yandex` (актуальная 0.241.x, ПРОВЕРИТЬ на registry.terraform.io/providers/yandex-cloud/yandex,
      провайдер выходит очень часто: обновите `~> 0.241` в `versions.tf` и закоммитьте свежий lock-файл).
- [ ] **Зеркало провайдера.** Если registry.terraform.io недоступен: `.terraformrc` с `network_mirror` Yandex
      (https://yandex.cloud/ru/docs/terraform/quickstart).
- [ ] **lock-файл.** После `terraform init` в каждом окружении: `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64`
      (ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ), закоммитить `.terraform.lock.hcl`.
- [ ] **Бакет под state.** Создать через `instructor/bootstrap-state-bucket` (нужен сервисный аккаунт и статический ключ).
      Студентам ключи **не раздаём**: ключ даёт запись во все state, любой может перезаписать чужой state или прочитать секреты из него.
      У студентов (★4) свой бакет и свои ключи.
- [ ] **Проверка блокировки (use_lockfile).** В документации Yandex Cloud про backend описан вариант с YDB, а `use_lockfile` не упомянут
      (https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-state-storage). Object Storage поддерживает условную запись
      `If-None-Match`, на которой строится lock-файл, но **проверьте на своём бакете**:
      два терминала, в первом `terraform apply` (останавливаете на вопросе подтверждения), во втором `terraform plan`:
      ожидаем `Error acquiring the state lock`. Если lock-файла не появилось (`<key>.tflock` рядом со state) или второй `plan` проходит,
      используйте запасной вариант: YDB + `dynamodb_table` (https://yandex.cloud/ru/docs/ydb/tutorials/terraform-state-lock;
      в документации блокировка через Document API объявлена устаревшей с Terraform 1.11, и будет удалена) или покажите слайд без live-демо блокировки.
- [ ] **Стартовый стенд для moved.** В `00-start/`: `terraform apply`, затем `cp 00-start/terraform.tfstate environments/dev/`.
      Репетиция: `cd environments/dev && terraform init && terraform plan` должен показать 5 `has moved to`, `0 to add` и `0 to destroy`.
- [ ] **Репетиция на секундомер** (60 минут, см. тайм-план). Запишите заранее скриншоты/вывод plan и apply как запасной вариант.
- [ ] **Токены.** `export YC_TOKEN=$(yc iam create-token)` живёт ограниченное время: обновите перед вебинаром.
- [ ] **Проверка сторожа prod.** В `environments/prod`: `terraform apply`, затем `terraform destroy` должен упасть с `Instance cannot be destroyed`
      (проверьте формулировку на своей версии Terraform). Затем `terraform state rm terraform_data.destroy_guard && terraform destroy`.
- [ ] **Prod к началу вебинара.** Для демо сторожа (`terraform plan -destroy` в prod упирается в `prevent_destroy`) prod должен быть уже применён:
      сделайте `apply` за час до начала (2 ВМ, 2 диска) и заранее перенесите его state в бакет (`init -migrate-state`).
      Если не хотите платить за prod, покажите сторожа слайдом/записью.

## За час до вебинара

- [ ] Терминал крупным шрифтом; два окна: `00-start/`, `environments/dev/`.
- [ ] Стартовый стенд применён (state в `00-start`), копия state лежит в `environments/dev/`.
- [ ] `terraform.tfvars` для dev и prod заполнены, **не видны на экране** (демонстрируйте `terraform.tfvars.example`).
- [ ] Бакет создан, ключи в окружении (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), **не показывайте** их на экране и в истории терминала.
- [ ] Закрыты вкладки с секретами; уведомления отключены.
- [ ] Ссылка на репозиторий вебинара и на ДЗ готова для чата.

## Уборка после вебинара (и напоминание студентам)

Порядок (от окружений к бакету):

```bash
# 1. dev
cd environments/dev && terraform destroy

# 2. prod: сторож блокирует destroy, поэтому сначала убираем его из state
cd ../prod
terraform state rm terraform_data.destroy_guard
terraform destroy

# 3. если state перенесли в бакет: после destroy в бакете остаются пустые state-объекты, это нормально

# 4. бакет и сервисный аккаунт (force_destroy = true удалит содержимое с версиями)
cd ../../instructor/bootstrap-state-bucket && terraform destroy -var yc_cloud_id=... -var yc_folder_id=... -var bucket_name=...
```

Проверка, что в облаке пусто:

```bash
yc compute instance list
yc compute disk list
yc vpc network list
yc vpc security-group list
yc storage bucket list
yc iam service-account list
```

Если вы удаляли сеть `default`, при необходимости пересоздайте её вручную (консоль: «Сеть» > «Создать сеть» с подсетями).
Студентам: после проверки ДЗ выполнить `terraform destroy` в обоих окружениях и удалить свой бакет (★4), проверить консоль на «забытые» диски.
Отдельно напомните: диски и публичные IP тарифицируются, пока существуют.
