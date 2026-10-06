output "id" {
  description = "ID ВМ."
  value       = yandex_compute_instance.this.id
}

output "internal_ip" {
  description = "Внутренний IP."
  value       = yandex_compute_instance.this.network_interface[0].ip_address
}

output "external_ip" {
  description = "Публичный IP."
  value       = yandex_compute_instance.this.network_interface[0].nat_ip_address
}
