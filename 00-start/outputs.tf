output "vm_external_ip" {
  description = "Публичный IP ВМ"
  value       = yandex_compute_instance.web.network_interface.0.nat_ip_address # БОЛЬ №7: старый синтаксис .0
}

output "vm_internal_ip" {
  description = "Внутренний IP ВМ"
  value       = yandex_compute_instance.web.network_interface.0.ip_address
}

output "vm_id" {
  description = "ID ВМ"
  value       = yandex_compute_instance.web.id
}

output "ssh_command" {
  description = "Команда для подключения по SSH"
  value       = "ssh ubuntu@${yandex_compute_instance.web.network_interface.0.nat_ip_address}"
}

output "web_url" {
  description = "Адрес nginx"
  value       = "http://${yandex_compute_instance.web.network_interface.0.nat_ip_address}"
}
