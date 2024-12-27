# based on https://github.com/andre-richter/vfio-pci-bind/tree/master

resource "ssh_resource" "opnsense_nic_vfio_driver_binding" {
  host        = var.k3s_ip_address
  user        = var.k3s_username
  private_key = var.k3s_ssh_private_key

  file {
    content     = <<-EOF
      # udev rules file that binds selected PCI devices to vfio-pci instead of
      # whatever driver udev and modprobe would ordinarily bind them to.
      #
      # This rules file should be located in /etc/udev/rules.d/
      # vfio-pci-bind.sh must be located in /lib/udev/ and must be executable.
      #
      ACTION!="add", GOTO="vfio_pci_bind_rules_end"
      SUBSYSTEM!="pci", GOTO="vfio_pci_bind_rules_end"


      # Identify PCI devices to be bound to vfio-pci using udev matching rules and
      # tag each device with "vfio-pci-bind".
      #
      # Example: Match any PCI device with <Vendor:Device> 1912:0014
      #   ATTR{vendor}=="0x1912", ATTR{device}=="0x0014", TAG="vfio-pci-bind"
      #
      # Example: Match the PCI device with <Domain:Bus:Device.Function> 0000:0b:00.0
      #  KERNEL=="0000:0b:00.0", TAG="vfio-pci-bind"
      #
      ATTR=="0x${var.opnsense_nic_vendor_id}", ATTR=="0x${var.opnsense_nic_product_id}", TAG="vfio-pci-bind"


      # Any device tagged by a rule above is bound to vfio-pci.
      #
      TAG=="vfio-pci-bind", RUN+="vfio-pci-bind.sh $kernel"
      LABEL="vfio_pci_bind_rules_end"
    EOF
    destination = "~/25-vfio-pci-bind.rules"
  }

  file {
    content     = <<-EOF
      # udev rules file that binds selected PCI devices to vfio-pci instead of
      # whatever driver udev and modprobe would ordinarily bind them to.
      #
      # This rules file should be located in /etc/udev/rules.d/
      # vfio-pci-bind.sh must be located in /lib/udev/ and must be executable.
      #
      ACTION!="add", GOTO="vfio_pci_bind_rules_end"
      SUBSYSTEM!="pci", GOTO="vfio_pci_bind_rules_end"


      # Identify PCI devices to be bound to vfio-pci using udev matching rules and
      # tag each device with "vfio-pci-bind".
      #
      # Example: Match any PCI device with <Vendor:Device> 1912:0014
      #   ATTR{vendor}=="0x1912", ATTR{device}=="0x0014", TAG="vfio-pci-bind"
      #
      # Example: Match the PCI device with <Domain:Bus:Device.Function> 0000:0b:00.0
      #  KERNEL=="0000:0b:00.0", TAG="vfio-pci-bind"
      #


      # Any device tagged by a rule above is bound to vfio-pci.
      #
      TAG=="vfio-pci-bind", RUN+="vfio-pci-bind.sh $kernel"
      LABEL="vfio_pci_bind_rules_end"
    EOF
    destination = "~/vfio-pci-bind.sh"
  }

  commands = [
    "sudo mv ~/25-vfio-pci-bind.rules /lib/udev/rules.d/25-vfio-pci-bind.rules",
    "sudo mv ~/vfio-pci-bind.sh /lib/udev/vfio-pci-bind.sh",
    "sudo chmod +x /lib/udev/vfio-pci-bind.sh",
    "sudo /lib/udev/vfio-pci-bind.sh ${var.opnsense_nic_vendor_id}:${var.opnsense_nic_product_id}",
  ]

  timeout = "1m"
}
