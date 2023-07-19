[Interface]
Address = ${vpn_ip }/${vpn_netlen}
PrivateKey = ${vpn_private_key}
DNS = 1.1.1.1

[Peer]
PublicKey  = ${vpn_endpoint_public_key}
AllowedIPs = 0.0.0.0/0
Endpoint = ${vpn_endpoint}:${vpn_endpoint_port}
