resource "harbor_config_auth" "oidc" {
  auth_mode          = "oidc_auth"
  primary_auth_mode  = true
  oidc_name          = "keycloak"
  oidc_endpoint      = data.terraform_remote_state.keycloak_config.outputs.keycloak_issuer_url
  oidc_client_id     = keycloak_openid_client.harbor.client_id
  oidc_client_secret = random_password.keycloak_client_secret.result
  oidc_scope         = "openid"
  oidc_verify_cert   = true
  oidc_auto_onboard  = true
  oidc_user_claim    = "preferred_username"
  oidc_groups_claim  = "roles"
  oidc_admin_group   = keycloak_role.harbor_admin.name
  oidc_group_filter  = "matchnothing^"
}
