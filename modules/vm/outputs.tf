output "servers" {
  description = "Карта серверов по ключам из var.servers: id, name, internal_ip, external_ip."
  value = {
    for key, instance in yandex_compute_instance.this : key => {
      id          = instance.id
      name        = instance.name
      internal_ip = instance.network_interface[0].ip_address
      external_ip = instance.network_interface[0].nat_ip_address
    }
  }
}
