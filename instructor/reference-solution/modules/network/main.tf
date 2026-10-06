resource "yandex_vpc_network" "this" {
  name = "${var.name_prefix}-network"
}

resource "yandex_vpc_subnet" "this" {
  name           = "${var.name_prefix}-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.subnet_cidr]
}

resource "yandex_vpc_security_group" "web" {
  name       = "${var.name_prefix}-web-sg"
  network_id = yandex_vpc_network.this.id

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      protocol       = "TCP"
      description    = ingress.key
      port           = ingress.value.port
      v4_cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
