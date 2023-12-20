resource "ssh_resource" "cron_jobs" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  commands = [
    "(sudo crontab -l 2>/dev/null; echo \"0 0 */14 * * zpool scrub vault\") | sudo crontab -",
  ]

  depends_on = [
    ssh_resource.apt_packages,
  ]
}
