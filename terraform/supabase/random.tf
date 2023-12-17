resource "random_password" "jwt_secret" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "db_username" {
  length  = 20
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "db_password" {
  length  = 20
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "dashboard_username" {
  length  = 20
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "dashboard_password" {
  length  = 20
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "logflare_logger_backend_api_key" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "logflare_api_key" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "secret_base_key" {
  length  = 64
  numeric = true
  special = false
  upper   = true
}
