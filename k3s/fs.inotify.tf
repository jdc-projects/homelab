resource "ssh_resource" "fs_inotify_update" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  file {
    content = <<-EOF
      fs.inotify.max_queued_events = 65536
      fs.inotify.max_user_instances = 512
      fs.inotify.max_user_watches = 996788
    EOF
    destination = "99-inotify.conf"
  }

  commands = [
    "sudo mv ./99-inotify.conf /etc/sysctl.d/99-inotify.conf",
    "sudo sysctl --system >/dev/null 2>&1 || true",
  ]
}
