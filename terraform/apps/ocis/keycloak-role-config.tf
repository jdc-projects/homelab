resource "keycloak_role" "ocis_admin_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  client_id   = null_resource.ocis_keycloak_client_id.triggers.client_id
  name        = "ocisAdmin"
  description = "OCIS Admin"
}

resource "keycloak_role" "ocis_space_admin_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  client_id   = null_resource.ocis_keycloak_client_id.triggers.client_id
  name        = "ocisSpaceAdmin"
  description = "OCIS Space Admin"
}

resource "keycloak_role" "ocis_user_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  client_id   = null_resource.ocis_keycloak_client_id.triggers.client_id
  name        = "ocisUser"
  description = "OCIS User"
}

resource "keycloak_role" "ocis_guest_client_role" {
  realm_id    = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  client_id   = null_resource.ocis_keycloak_client_id.triggers.client_id
  name        = "ocisGuest"
  description = "OCIS Guest"
}

resource "keycloak_group_roles" "ocis_admin_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  group_id = "ocis_admin"

  role_ids = [
    keycloak_role.ocis_admin_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_space_admin_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  group_id = "ocis_space_admin"

  role_ids = [
    keycloak_role.ocis_space_admin_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_user_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  group_id = "ocis_user"

  role_ids = [
    keycloak_role.ocis_user_client_role.id
  ]
}

resource "keycloak_group_roles" "ocis_guest_group_role" {
  realm_id = data.terraform_remote_state.keycloak_config.outputs.keycloak_lldap_realm_id
  group_id = "ocis_guest"

  role_ids = [
    keycloak_role.ocis_guest_client_role.id
  ]
}
