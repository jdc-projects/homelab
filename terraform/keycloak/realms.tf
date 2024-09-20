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

  sso_session_idle_timeout = "120h" # 5 days
  sso_session_max_lifespan = "720h" # 30 days

  offline_session_idle_timeout         = "720h" # 30 days
  offline_session_max_lifespan_enabled = true
  offline_session_max_lifespan         = "2160h" # 90 days

  depends_on = [
    null_resource.keycloak_liveness_check,
  ]
}
