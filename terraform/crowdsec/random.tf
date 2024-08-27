resource "random_password" "crowdsec_agent_username" {
  length  = 50
  numeric = true
  special = false
  upper   = false
}

resource "random_password" "crowdsec_agent_password" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "traefik_api_key" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}
