# Переходный файл: переносит ресурсы из плоского 00-start в модули БЕЗ пересоздания.
# Работает, если в этой директории лежит state от 00-start (cp ../../00-start/terraform.tfstate .).
# После успешного apply (и когда у всех копий state перенос выполнен) файл можно удалить.
#
# Ресурсы переезжают, data-источники нет: data.yandex_compute_image просто читается заново.

moved {
  from = yandex_vpc_network.workshop
  to   = module.network.yandex_vpc_network.this
}

moved {
  from = yandex_vpc_subnet.workshop
  to   = module.network.yandex_vpc_subnet.this
}

moved {
  from = yandex_vpc_security_group.web_sg
  to   = module.network.yandex_vpc_security_group.web
}

moved {
  from = yandex_compute_disk.data
  to   = module.vm.yandex_compute_disk.data["web"]
}

moved {
  from = yandex_compute_instance.web
  to   = module.vm.yandex_compute_instance.this["web"]
}
