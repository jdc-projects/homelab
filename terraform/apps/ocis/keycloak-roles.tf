data "keycloak_group" "app_admins" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "app_admins"
}

data "keycloak_group" "app_users" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "app_users"
}

data "keycloak_group" "app_guests" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "app_guests"
}

resource "keycloak_role" "ocis_admin" {
  for_each = tomap({
    ocis_web_id     = keycloak_openid_client.ocis_web.id
    ocis_desktop_id = keycloak_openid_client.ocis_desktop.id
    ocis_android_id = keycloak_openid_client.ocis_android.id
    ocis_ios_id     = keycloak_openid_client.ocis_ios.id
  })

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value
  name        = "ocisAdmin"
  description = "OCIS Admin"

  provisioner "local-exec" {
    command = "sleep 1"
  }
}

resource "keycloak_role" "ocis_user" {
  for_each = tomap({
    ocis_web_id     = keycloak_openid_client.ocis_web.id
    ocis_desktop_id = keycloak_openid_client.ocis_desktop.id
    ocis_android_id = keycloak_openid_client.ocis_android.id
    ocis_ios_id     = keycloak_openid_client.ocis_ios.id
  })

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value
  name        = "ocisUser"
  description = "OCIS User"

  provisioner "local-exec" {
    command = "sleep 1"
  }
}

resource "keycloak_role" "ocis_guest" {
  for_each = tomap({
    ocis_web_id     = keycloak_openid_client.ocis_web.id
    ocis_desktop_id = keycloak_openid_client.ocis_desktop.id
    ocis_android_id = keycloak_openid_client.ocis_android.id
    ocis_ios_id     = keycloak_openid_client.ocis_ios.id
  })

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value
  name        = "ocisGuest"
  description = "OCIS Guest"

  provisioner "local-exec" {
    command = "sleep 1"
  }
}

resource "keycloak_group_roles" "ocis_admin" {
  for_each = keycloak_role.ocis_admin

  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_admins.id

  role_ids = [
    each.value.id
  ]

  depends_on = [
    keycloak_role.ocis_admin,
    keycloak_role.ocis_user,
    keycloak_role.ocis_guest
  ]
}

resource "keycloak_group_roles" "ocis_user" {
  for_each = keycloak_role.ocis_user

  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_users.id

  role_ids = [
    each.value.id
  ]

  depends_on = [
    keycloak_role.ocis_admin,
    keycloak_role.ocis_user,
    keycloak_role.ocis_guest
  ]
}

resource "keycloak_group_roles" "ocis_guest" {
  for_each = keycloak_role.ocis_guest

  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_guests.id

  role_ids = [
    each.value.id
  ]

  depends_on = [
    keycloak_role.ocis_admin,
    keycloak_role.ocis_user,
    keycloak_role.ocis_guest
  ]
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ocis_claim_mapper" {
  for_each = tomap({
    ocis_web = tomap({
      id        = keycloak_openid_client.ocis_web.id
      client_id = keycloak_openid_client.ocis_web.client_id
    })
    ocis_desktop = tomap({
      id        = keycloak_openid_client.ocis_desktop.id
      client_id = keycloak_openid_client.ocis_desktop.client_id
    })
    ocis_android = tomap({
      id        = keycloak_openid_client.ocis_android.id
      client_id = keycloak_openid_client.ocis_android.client_id
    })
    ocis_ios = tomap({
      id        = keycloak_openid_client.ocis_ios.id
      client_id = keycloak_openid_client.ocis_ios.client_id
    })
  })

  realm_id                    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id                   = each.value.id
  name                        = "role-mapper"
  claim_name                  = "roles"
  client_id_for_role_mappings = each.value.client_id

  multivalued = "true"

  add_to_id_token     = "false"
  add_to_access_token = "false"
  add_to_userinfo     = "true"
}
