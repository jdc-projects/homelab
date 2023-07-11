resource "keycloak_role" "ocis_admin" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = keycloak_openid_client.ocis_web.client_id
  name        = "ocisAdmin"
  description = "OCIS Admin"
}

resource "keycloak_role" "ocis_user" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = keycloak_openid_client.ocis_web.client_id
  name        = "ocisUser"
  description = "OCIS User"
}

resource "keycloak_role" "ocis_guest" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = keycloak_openid_client.ocis_web.client_id
  name        = "ocisGuest"
  description = "OCIS Guest"
}

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

resource "keycloak_group_roles" "ocis_admin" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_admins.id

  role_ids = [
    keycloak_role.ocis_admin.id
  ]
}

resource "keycloak_group_roles" "ocis_user" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_users.id

  role_ids = [
    keycloak_role.ocis_user.id
  ]
}

resource "keycloak_group_roles" "ocis_guest" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.app_guests.id

  role_ids = [
    keycloak_role.ocis_guest.id
  ]
}
