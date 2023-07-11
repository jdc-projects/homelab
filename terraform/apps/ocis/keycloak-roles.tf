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
  for_each = toset([
    keycloak_openid_client.ocis_web.id,
    keycloak_openid_client.ocis_desktop.id,
    keycloak_openid_client.ocis_android.id,
    keycloak_openid_client.ocis_ios.id
  ])

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value
  name        = "ocisAdmin"
  description = "OCIS Admin"
}

resource "keycloak_role" "ocis_user" {
  for_each = toset([
    keycloak_openid_client.ocis_web.id,
    keycloak_openid_client.ocis_desktop.id,
    keycloak_openid_client.ocis_android.id,
    keycloak_openid_client.ocis_ios.id
  ])

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value
  name        = "ocisUser"
  description = "OCIS User"
}

resource "keycloak_role" "ocis_guest" {
  for_each = toset([
    keycloak_openid_client.ocis_web.id,
    keycloak_openid_client.ocis_desktop.id,
    keycloak_openid_client.ocis_android.id,
    keycloak_openid_client.ocis_ios.id
  ])

  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = each.value
  name        = "ocisGuest"
  description = "OCIS Guest"
}

resource "keycloak_group_roles" "ocis_admin" {
  for_each = keycloak_role.ocis_admin

  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_admins.id

  role_ids = [
    each.value.id
  ]
}

resource "keycloak_group_roles" "ocis_user" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_users.id

  role_ids = [
    each.value.id
  ]
}

resource "keycloak_group_roles" "ocis_guest" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_guests.id

  role_ids = [
    each.value.id
  ]
}
