data "local_file" "memberof" {
  filename = "./schemas/00-memberof.ldif"
}

data "local_file" "rfc2307bis" {
  filename = "./schemas/10-rfc2307bis.ldif"
}

resource "kubernetes_config_map" "openldap_custom_schemas" {
  metadata {
    name      = "openldap-custom-schemas"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    "00-memberof.ldif"   = data.local_file.memberof.content
    "10-rfc2307bis.ldif" = data.local_file.rfc2307bis.content
  }
}

resource "null_resource" "populate_custom_ldifs" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOF
      find ./ldifs -type f -exec sed -i'' -e "s#{{SERVER_BASE_DOMAIN}}#${var.server_base_domain}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_ADMIN_USERNAME}}#${random_password.openldap_admin_username.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_TEST_ADMIN_USERNAME}}#${random_password.openldap_test_admin_username.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_TEST_USER_USERNAME}}#${random_password.openldap_test_user_username.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_TEST_GUEST_USERNAME}}#${random_password.openldap_test_guest_username.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_TEST_DISABLED_USERNAME}}#${random_password.openldap_test_disabled_username.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_ADMIN_PASSWORD}}#${random_password.openldap_admin_password.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_TEST_ADMIN_PASSWORD}}#${random_password.openldap_test_admin_password.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_TEST_USER_PASSWORD}}#${random_password.openldap_test_user_password.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_TEST_GUEST_PASSWORD}}#${random_password.openldap_test_guest_password.result}#g" {} \;
      find ./ldifs -type f -exec sed -i'' -e "s#{{OPENLDAP_TEST_DISABLED_PASSWORD}}#${random_password.openldap_test_disabled_password.result}#g" {} \;
      rm -rf ./config/*-e*
    EOF
  }
}

data "local_file" "base" {
  filename = "./ldifs/00-base.ldif"

  depends_on = [null_resource.populate_custom_ldifs]
}

data "local_sensitive_file" "users" {
  filename = "./ldifs/70-users.ldif"

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
    "00-base.ldif"   = data.local_file.base.content
    "70-users.ldif"  = data.local_sensitive_file.users.content
    "80-groups.ldif" = data.local_file.groups.content
  }
}
