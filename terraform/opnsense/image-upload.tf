# the PVC download method doesn't work, so we have to use the CLI to upload the OPNsense image
resource "null_resource" "image_upload" {
  triggers = {
    opnsense_version  = "24.7"
    image_size        = "4Gi"
    image_upload_name = "opnsense-24-7-nano-amd64"
    image_namespace   = kubernetes_namespace.opnsense.metadata[0].name
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOF
      curl -Lo opnsense.img.bz2 https://www.mirrorservice.org/sites/opnsense.org/releases/${self.triggers.opnsense_version}/OPNsense-${self.triggers.opnsense_version}-nano-amd64.img.bz2
      bzip2 -d opnsense.img.bz2
      virtctl image-upload dv ${self.triggers.image_upload_name} -n ${self.triggers.image_namespace} --size ${self.triggers.image_size} --image-path ./opnsense.img --uploadproxy-url=https://${var.k3s_ip_address}:31001 --insecure --access-mode ReadWriteOnce --volume-mode filesystem --storage-class openebs-zfs-localpv-bulk-no-backup
      rm opnsense.img
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      kubectl -n ${self.triggers.image_namespace} delete dv ${self.triggers.image_upload_name}
    EOF
  }

  depends_on = [
    kubernetes_namespace.opnsense
  ]
}
