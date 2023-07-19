resource "local_file" "ssh_config" {
  content = templatefile("templates/ssh.cfg.tpl", {
    server_name = var.vpn_server.name,
    server_ip = var.vpn_server.local_ip,
    ssh_username  = var.vpn_server.username,
    ssh_key_file  = var.vpn_server.ssh_key_file
    })
    
  filename        = "local/ssh.cfg"
  file_permission = "0640"
}


