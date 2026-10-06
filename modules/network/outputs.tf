output "network_id" {
  description = "ID сети."
  value       = yandex_vpc_network.this.id
}

output "subnet_id" {
  description = "ID подсети."
  value       = yandex_vpc_subnet.this.id
}

output "security_group_id" {
  description = "ID security group для веб-серверов."
  value       = yandex_vpc_security_group.web.id
}
