resource "null_resource" "get_custom_schemas" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOF
        mkdir ./schemas
        cd ./schemas
        curl https://raw.githubusercontent.com/github/github-ldap/master/test/fixtures/openldap/memberof.ldif -o memberof.ldif
      EOF
  }
}

data "local_file" "memberof" {
  filename = "./ldifs/memberof.ldif"

  depends_on = [null_resource.get_custom_schemas]
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
