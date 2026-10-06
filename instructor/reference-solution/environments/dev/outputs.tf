output "vm_external_ip" {
  description = "Публичный IP."
  value       = module.vm.external_ip
}

output "web_url" {
  description = "Адрес nginx."
  value       = "http://${module.vm.external_ip}"
}
