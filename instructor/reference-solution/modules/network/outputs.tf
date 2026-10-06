output "subnet_id" {
  description = "ID подсети."
  value       = yandex_vpc_subnet.this.id
}

output "security_group_id" {
  description = "ID security group."
  value       = yandex_vpc_security_group.web.id
}
