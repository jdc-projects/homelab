locals {
  cockpit_zfs_manager_version = "v1.3.1"
}

resource "ssh_resource" "cockpit_setup" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  commands = [
    "git clone --depth 1 -b ${local.cockpit_zfs_manager_version} https://github.com/45drives/cockpit-zfs-manager.git",
    "sudo cp -r ./cockpit-zfs-manager/zfs /usr/share/cockpit",
    "rm -tf ./cockpit-zfs-manager",
  ]

  depends_on = [
    ssh_resource.apt_packages,
  ]
}
