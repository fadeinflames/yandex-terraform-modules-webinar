output "vm_external_ips" {
  description = "Публичные IP серверов по ключам."
  value       = { for key, s in module.vm.servers : key => s.external_ip }
}

output "vm_internal_ips" {
  description = "Внутренние IP серверов по ключам."
  value       = { for key, s in module.vm.servers : key => s.internal_ip }
}

output "vm_ids" {
  description = "ID серверов по ключам."
  value       = { for key, s in module.vm.servers : key => s.id }
}

output "ssh_commands" {
  description = "Команды SSH по ключам."
  value       = { for key, s in module.vm.servers : key => "ssh ubuntu@${s.external_ip}" }
}

output "web_urls" {
  description = "Адреса nginx по ключам."
  value       = { for key, s in module.vm.servers : key => "http://${s.external_ip}" }
}
