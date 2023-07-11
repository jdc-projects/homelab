resource "keycloak_group_roles" "ocis_admin_web" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_admins.id

  role_ids = [
    keycloak_role.ocis_admin["ocis_web"].id
  ]

  provisioner "local-exec" {
    command = "sleep 1"
  }
}

resource "keycloak_group_roles" "ocis_user_web" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_users.id

  role_ids = [
    keycloak_role.ocis_user["ocis_web"].id
  ]

  provisioner "local-exec" {
    command = "sleep 1"
  }

  depends_on = [keycloak_group_roles.ocis_admin_android]
}

resource "keycloak_group_roles" "ocis_guest_web" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_guests.id

  role_ids = [
    keycloak_role.ocis_guest["ocis_web"].id
  ]

  provisioner "local-exec" {
    command = "sleep 1"
  }

  depends_on = [keycloak_group_roles.ocis_user_android]
}
