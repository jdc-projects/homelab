data "keycloak_realm" "master" {
  realm = "master"
}

resource "keycloak_realm" "primary" {
  realm   = data.terraform_remote_state.keycloak.outputs.keycloak_realm_name
  enabled = true

  registration_email_as_username = false
  login_with_email_allowed       = false
  duplicate_emails_allowed       = true

  sso_session_idle_timeout = "24h"
  sso_session_max_lifespan = "24h"
}
