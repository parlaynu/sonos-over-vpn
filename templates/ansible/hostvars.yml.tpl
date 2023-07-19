---
server_name: ${server_name}
server_ifname: ${server_ifname}
private_ip: ${private_ip}
cidr_block: ${cidr_block}
gateway: ${gateway}

vpn_endpoint_address: ${vpn_endpoint_address}
vpn_endpoint_port: ${vpn_endpoint_port}

vpn_cidr_block: ${vpn_cidr_block}
vpn_ip: ${vpn_ip}
vpn_netlen: ${vpn_netlen}
vpn_private_key: ${vpn_private_key}

clients:
%{ for client in clients ~}
- name: ${client.name}
  vpn_ip: ${client.vpn_ip}
  public_key: ${client.public_key}
%{ endfor ~}
