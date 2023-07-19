
locals {
  gateway_role = "gateway"
  iptables_role = "iptables"
  pimd_role = "pimd"
}

resource "template_dir" "gateway" {
  source_dir      = "templates/ansible-roles/${local.gateway_role}"
  destination_dir = "local/ansible/roles/${local.gateway_role}"

  vars = {}
}

resource "template_dir" "iptables" {
  source_dir      = "templates/ansible-roles/${local.iptables_role}"
  destination_dir = "local/ansible/roles/${local.iptables_role}"

  vars = {}
}

resource "template_dir" "pimd" {
  source_dir      = "templates/ansible-roles/${local.pimd_role}"
  destination_dir = "local/ansible/roles/${local.pimd_role}"

  vars = {}
}
