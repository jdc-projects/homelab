resource "ssh_resource" "fs_inotify_update" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  commands = [
    "sudo echo -e \"fs.inotify.max_queued_events = 65536\" | sudo tee -a /etc/sysctl.conf",
    "sudo echo -e \"fs.inotify.max_user_instances=512\" | sudo tee -a /etc/sysctl.conf",
    "sudo echo -e \"fs.inotify.max_user_watches = 996788\" | sudo tee -a /etc/sysctl.conf",
  ]
}
