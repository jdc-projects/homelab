data "local_file" "memberof" {
  filename = "./schemas/memberof.ldif"
}

resource "kubernetes_config_map" "openldap_custom_schemas" {
  metadata {
    name      = "openldap-custom-schemas"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    "memberof.ldif" = data.local_file.memberof.content
  }
}

resource "kubernetes_config_map" "openldap_custom_ldifs" {
  metadata {
    name      = "openldap-custom-ldifs"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
  }
}
