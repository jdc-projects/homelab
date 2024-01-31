resource "random_password" "vaultwarden_admin_token" {
  length  = 40
  numeric = true
  special = false
  upper   = true
}

resource "random_password" "vaultwarden_db_username" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "vaultwarden_db_password" {
  length  = 16
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = {
    username = random_password.vaultwarden_db_username.result
    password = random_password.vaultwarden_db_password.result
  }
}
