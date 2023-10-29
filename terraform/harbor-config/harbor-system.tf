resource "harbor_config_security" "main" {
  cve_allowlist = []
}

resource "harbor_config_system" "main" {
  project_creation_restriction = "adminonly"
  robot_token_expiration       = 30
  robot_name_prefix            = "robot$"
  scanner_skip_update_pulltime = "false"
}
