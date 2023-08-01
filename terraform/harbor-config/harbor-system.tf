resource "harbor_config_email" "main" {
    email_host = var.smtp_host
    email_port = var.smtp_port
    email_username = var.smtp_username
    email_password = var.smtp_password
    email_from = "noreply@${var.server_base_domain}"
    email_ssl = "true"
    email_insecure = "false"
}

resource "harbor_config_security" "main" {
  cve_allowlist = []
}

resource "harbor_config_system" "main" {
  project_creation_restriction = "adminonly"
  robot_token_expiration       = 30
  robot_name_prefix            = "robot$"
  scanner_skip_update_pulltime = "false"
}
