
resource "local_file" "client_configs" {
  for_each = toset(var.vpn_clients)

  content = templatefile("templates/wireguard-client.conf.tpl", {
    vpn_ip           = local.vpn_client_vpn_ips[index(var.vpn_clients, each.key)]
    vpn_netlen       = split("/", var.vpn_network.cidr_block)[1]
    vpn_private_key  = wireguard_asymmetric_key.vpn_clients[each.key].private_key,

    vpn_endpoint            = var.vpn_network.endpoint
    vpn_endpoint_port       = var.vpn_network.listen_port
    vpn_endpoint_public_key = wireguard_asymmetric_key.vpn_server.public_key
  })
    
  filename        = "local/clients/${each.key}.conf"
  file_permission = "0640"
}

