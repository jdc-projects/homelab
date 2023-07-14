data "keycloak_realm" "master" {
  realm = "master"
}

resource "keycloak_realm" "server_base_domain" {
  realm   = var.server_base_domain
  enabled = true

  registration_email_as_username = false
  login_with_email_allowed       = false
  duplicate_emails_allowed       = true
}
