## render the run script

resource "local_file" "run_playbook" {
  content = templatefile("templates/ansible/run-ansible.sh.tpl", {
      inventory_file = "inventory.ini"
    })
  filename = "local/ansible/run-ansible.sh"
  file_permission = "0755"
}


## render the playbook

resource "local_file" "playbook" {
  content = templatefile("templates/ansible/playbook.yml.tpl", {
      gateway_role = local.gateway_role,
      iptables_role = local.iptables_role,
      pimd_role = local.pimd_role,
      wireguard_role = local.wireguard_role
    })
  filename = "local/ansible/playbook.yml"
}


## render host variables

resource "local_file" "hostvars" {

  content = templatefile("templates/ansible/hostvars.yml.tpl", {
    server_name      = var.vpn_server.name,
    server_ifname    = var.vpn_server.interface,
    private_ip       = var.vpn_server.local_ip,
    cidr_block       = var.local_network.cidr_block
    gateway          = var.local_network.gateway

    vpn_endpoint_address = var.vpn_network.endpoint,
    vpn_endpoint_port    = var.vpn_network.listen_port
    
    vpn_cidr_block   = var.vpn_network.cidr_block
    vpn_netlen       = split("/", var.vpn_network.cidr_block)[1]
    vpn_ip           = local.vpn_server_vpn_ip
    vpn_private_key  = wireguard_asymmetric_key.vpn_server.private_key,
    
    clients = [for client in var.vpn_clients :
        {
          name = client
          vpn_ip  = local.vpn_client_vpn_ips[index(var.vpn_clients, client)]
          public_key = wireguard_asymmetric_key.vpn_clients[client].public_key
        }
      ]
    })
    
  filename        = "local/ansible/host_vars/${var.vpn_server.name}.yml"
  file_permission = "0640"
}


## render the inventory file

resource "local_file" "inventory" {
  content = templatefile("templates/ansible/inventory.ini.tpl", {
    server = var.vpn_server.name
    })
  filename = "local/ansible/inventory.ini"
  file_permission = "0640"
}
