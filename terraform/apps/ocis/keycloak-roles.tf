resource "keycloak_role" "ocis_admin_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name        = "ocisAdmin"
  description = "OCIS Admin"
}

resource "keycloak_role" "ocis_space_admin_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name        = "ocisSpaceAdmin"
  description = "OCIS Space Admin"
}

resource "keycloak_role" "ocis_user_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name        = "ocisUser"
  description = "OCIS User"
}

resource "keycloak_role" "ocis_guest_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
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
  group_id = data.keycloak_group.ocis_admin_group.id

  role_ids = [
    keycloak_role.ocis_admin_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_space_admin_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.ocis_space_admin_group.id

  role_ids = [
    keycloak_role.ocis_space_admin_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_user_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.ocis_user_group.id

  role_ids = [
    keycloak_role.ocis_user_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_guest_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  group_id = data.keycloak_group.ocis_guest_group.id

  role_ids = [
    keycloak_role.ocis_guest_client_role.id
  ]
}

data "keycloak_openid_client_scope" "keycloak_acr_scope" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "acr"
}

resource "keycloak_openid_user_realm_role_protocol_mapper" "user_realm_role_mapper" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_jack_chapman_co_uk_realm_id
  name     = "user-realm-role-mapper"

  client_scope_id = data.keycloak_openid_client_scope.keycloak_acr_scope.id

  claim_name       = "roles"
  claim_value_type = "String"

  multivalued = true

  add_to_id_token     = false
  add_to_access_token = false
  add_to_userinfo     = true
}
