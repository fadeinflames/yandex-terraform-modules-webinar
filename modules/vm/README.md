# Модуль vm

Одна или несколько ВМ с nginx (cloud-init через `templatefile`), опциональным диском данных на каждый сервер.

Принципы интерфейса:
- серверы описываются картой `servers` (ключ становится частью имени ВМ);
- SSH-ключ передаётся **содержимым**, модуль не читает файлы с машины запускающего;
- `prevent_destroy` в модуле нет (lifecycle принимает только литералы): защита prod живёт на уровне окружения.

Пример вызова: `environments/dev/main.tf`.

<!-- BEGIN_TF_DOCS -->
<!-- Блок генерируется командой: terraform-docs markdown table --output-file README.md --output-mode inject modules/vm -->
<!-- END_TF_DOCS -->
