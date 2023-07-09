resource "null_resource" "get_custom_ldif" {
  provisioner "local-exec" {
    command = <<-EOF
        mkdir ./ldifs
        cd ./ldifs
        wget https://raw.githubusercontent.com/osixia/docker-openldap/635034a75878773f8576d646422cf26e43741fab/image/service/slapd/assets/config/bootstrap/schema/rfc2307bis.ldif
      EOF
  }
}

data "local_file" "rfc2307bis" {
  filename = "./ldifs/rfc2307bis.ldif"

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
