resource "keycloak_group_roles" "ocis_admin_ios" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_admins.id

  role_ids = [
    keycloak_role.ocis_admin["ocis_ios"].id
  ]

  provisioner "local-exec" {
    command = "sleep 1"
  }

  depends_on = [ keycloak_group_roles.keycloak_group_roles.ocis_admin_web ]
}

resource "keycloak_group_roles" "ocis_user_ios" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_users.id

  role_ids = [
    keycloak_role.ocis_user["ocis_ios"].id
  ]

  provisioner "local-exec" {
    command = "sleep 1"
  }

  depends_on = [ keycloak_group_roles.keycloak_group_roles.ocis_user_web ]
}

resource "keycloak_group_roles" "ocis_guest_ios" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_guests.id

  role_ids = [
    keycloak_role.ocis_guest["ocis_ios"].id
  ]

  provisioner "local-exec" {
    command = "sleep 1"
  }

  depends_on = [ keycloak_group_roles.keycloak_group_roles.ocis_guest_web ]
}