data "keycloak_group" "app_admins" {
  realm_id = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  name     = "app_admins"
}

data "keycloak_group" "app_users" {
  realm_id = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  name     = "app_users"
}

resource "keycloak_role" "ollama_admin" {
  realm_id    = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id   = keycloak_openid_client.ollama.id
  name        = "ollamaAdmin"
  description = "ollama Admin"
}

resource "keycloak_group_roles" "ollama_admin" {
  realm_id = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  group_id = data.keycloak_group.app_admins.id

  role_ids = [
    keycloak_role.ollama_admin.id
  ]

  exhaustive = false
}

resource "keycloak_role" "ollama_user" {
  realm_id    = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id   = keycloak_openid_client.ollama.id
  name        = "ollamaUser"
  description = "ollama User"
}

resource "keycloak_group_roles" "ollama_user" {
  for_each = toset([
    data.keycloak_group.app_users.id,
  ])

  realm_id = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  group_id = data.keycloak_group.app_users.id

  role_ids = [
    keycloak_role.ollama_user.id
  ]

  exhaustive = false
}

resource "keycloak_openid_user_client_role_protocol_mapper" "ollama_claim_mapper" {
  realm_id                    = data.terraform_remote_state.keycloak.outputs.primary_realm_id
  client_id                   = keycloak_openid_client.ollama.id
  name                        = "role-mapper"
  claim_name                  = "roles"
  client_id_for_role_mappings = keycloak_openid_client.ollama.client_id

  multivalued = "true"

  add_to_id_token     = "true"
  add_to_access_token = "true"
  add_to_userinfo     = "true"
}
