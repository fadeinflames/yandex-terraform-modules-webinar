# 00-start: плоский стартовый проект

Стенд целиком в одном `main.tf`: сеть, security group, диск, ВМ с nginx.
Это **исходная точка рефакторинга** для демо и домашнего задания: слабые места помечены комментариями «БОЛЬ №N».

```bash
cp terraform.tfvars.example terraform.tfvars   # подставить значения
terraform init && terraform apply
```

Здесь токен лежит в `terraform.tfvars`: так проще начать, но так делать нельзя. Сегодня мы от этого уходим.
Не коммитьте `terraform.tfvars` и `terraform.tfstate`.
