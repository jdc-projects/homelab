data "keycloak_realm" "master" {
  realm = "master"

  depends_on = [
    null_resource.keycloak_liveness_check,
  ]
}

resource "keycloak_realm" "primary" {
  realm   = data.terraform_remote_state.prometheus_operator.outputs.oauth_realm_name
  enabled = true

  registration_email_as_username = false
  login_with_email_allowed       = false
  duplicate_emails_allowed       = true

  sso_session_idle_timeout = "24h"
  sso_session_max_lifespan = "24h"

  depends_on = [
    null_resource.keycloak_liveness_check,
  ]
}
