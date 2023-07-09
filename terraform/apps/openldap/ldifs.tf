resource "null_resource" "get_custom_ldif" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOF
        mkdir ./ldifs
        cd ./ldifs
        curl https://raw.githubusercontent.com/jtyr/rfc2307bis/master/rfc2307bis.schema -o rfc2307bis.ldif
      EOF
  }
}

data "local_file" "rfc2307bis" {
  filename = "./ldifs/rfc2307bis.schema"

  depends_on = [null_resource.get_custom_ldif]
}

resource "kubernetes_config_map" "openldap_custom_ldifs" {
  metadata {
    name      = "openldap-custom-ldifs"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    "rfc2307bis.ldif" = data.local_file.rfc2307bis.content
  }
}
