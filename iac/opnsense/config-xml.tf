resource "null_resource" "config_xml" {
  triggers = {
    image_size        = "5Mi"
    image_upload_name = "opnsense-config"
    image_namespace   = kubernetes_namespace.opnsense.metadata[0].name
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOF
      mkdir -p ./${self.triggers.image_upload_name}/conf
      cp ./config.xml ./${self.triggers.image_upload_name}/conf/
      mkisofs -o ${self.triggers.image_upload_name}.iso ${self.triggers.image_upload_name}
      virtctl image-upload dv ${self.triggers.image_upload_name} -n ${self.triggers.image_namespace} --size ${self.triggers.image_size} --image-path ./${self.triggers.image_upload_name}.iso --uploadproxy-url=https://${var.k3s_ip_address}:31001 --insecure --access-mode ReadWriteOnce --volume-mode filesystem --storage-class openebs-zfs-localpv-general-no-backup
      rm ${self.triggers.image_upload_name}.iso
      rm -rf ./${self.triggers.image_upload_name}
    EOF
    # note: mkisofs -> genisoimage (for Linux)
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
