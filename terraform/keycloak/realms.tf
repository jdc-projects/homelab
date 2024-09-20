data "keycloak_realm" "master" {
  realm = "master"

  depends_on = [
    null_resource.keycloak_liveness_check,
  ]
}

resource "keycloak_realm" "primary" {
  realm   = var.server_base_domain
  enabled = true

  registration_allowed     = false
  login_with_email_allowed = false
  duplicate_emails_allowed = true

  sso_session_idle_timeout = "7d"
  sso_session_max_lifespan = "30d"

  offline_session_idle_timeout         = "30d"
  offline_session_max_lifespan_enabled = true
  offline_session_max_lifespan         = "90d"

  depends_on = [
    null_resource.keycloak_liveness_check,
  ]
}
