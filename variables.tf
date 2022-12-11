
variable "local_network" {
  type = object({
    cidr_block = string
    gateway = string
  })
  default = {
    cidr_block = "192.168.14.0/24"
    gateway = "192.168.14.1"
  }
}

variable "vpn_server" {
  type = object({
    name = string
    interface = string
    local_ip = string
    username = string
    ssh_key_file = string
  })
  default = {
    name = "sonos"
    interface = "eth0"
    local_ip = "192.168.14.4"
    username = "pi"
    ssh_key_file = "~/.ssh/rpi"
  }
}

variable "vpn_network" {
  type = object({
    endpoint = string
    listen_port = number
    cidr_block = string
  })
  default = {
    endpoint = "sonos.mydomain.com"   # DNS name or IP address
    listen_port = 51820
    cidr_block = "192.168.15.0/24"
  }  
}

variable "vpn_clients" {
  type    = list(string)
  default = ["laptop", "ipad"]
}

locals {
  vpn_server_vpn_ip = cidrhost(var.vpn_network.cidr_block, 1)
  vpn_client_vpn_ips = [for client in var.vpn_clients : cidrhost(var.vpn_network.cidr_block, index(var.vpn_clients, client)+5)]
}

