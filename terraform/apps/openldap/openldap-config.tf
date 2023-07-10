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

resource "null_resource" "populate_custom_ldifs" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOF
      find ./ldifs -type f -exec sed -i'' -e "s#{{SERVER_BASE_DOMAIN}}#${var.server_base_domain}#g" {} \;
      rm -rf ./config/*-e*
    EOF
  }
}

data "local_file" "base" {
  filename = "./ldifs/00-base.ldif"

  depends_on = [null_resource.populate_custom_ldifs]
}

data "local_file" "groups" {
  filename = "./ldifs/80-groups.ldif"

  depends_on = [null_resource.populate_custom_ldifs]
}

resource "kubernetes_config_map" "openldap_custom_ldifs" {
  metadata {
    name      = "openldap-custom-ldifs"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    "00-base.ldif" = data.local_file.base.content
    "80-groups.ldif" = data.local_file.groups.content
  }
}
