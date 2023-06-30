resource "keycloak_role" "ocis_admin_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = keycloak_openid_client.ocis_client.id
  name        = "ocisAdmin"
  description = "OCIS Admin"
}

resource "keycloak_role" "ocis_space_admin_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = keycloak_openid_client.ocis_client.id
  name        = "ocisSpaceAdmin"
  description = "OCIS Space Admin"
}

resource "keycloak_role" "ocis_user_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = keycloak_openid_client.ocis_client.id
  name        = "ocisUser"
  description = "OCIS User"
}

resource "keycloak_role" "ocis_guest_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  client_id   = keycloak_openid_client.ocis_client.id
  name        = "ocisGuest"
  description = "OCIS Guest"
}

data "keycloak_group" "ocis_admin_group" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "ocis_admin"
}

data "keycloak_group" "ocis_space_admin_group" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "ocis_space_admin"
}

data "keycloak_group" "ocis_user_group" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "ocis_user"
}

data "keycloak_group" "ocis_guest_group" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "ocis_guest"
}

resource "keycloak_group_roles" "ocis_admin_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = keycloak_group.ocis_admin_group.id

  role_ids = [
    keycloak_role.ocis_admin_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_space_admin_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = keycloak_group.ocis_space_admin_group.id

  role_ids = [
    keycloak_role.ocis_space_admin_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_user_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = keycloak_group.ocis_user_group.id

  role_ids = [
    keycloak_role.ocis_user_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_guest_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = keycloak_group.ocis_guest_group.id

  role_ids = [
    keycloak_role.ocis_guest_client_role.id
  ]
}
