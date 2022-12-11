
locals {
  wireguard_role = "wireguard"
}

resource "wireguard_asymmetric_key" "vpn_server" {
}

resource "wireguard_asymmetric_key" "vpn_clients" {
  for_each = toset(var.vpn_clients)
}


resource "template_dir" "wireguard" {
  source_dir      = "templates/ansible-roles/${local.wireguard_role}"
  destination_dir = "local/ansible/roles/${local.wireguard_role}"

  vars = {}
}
