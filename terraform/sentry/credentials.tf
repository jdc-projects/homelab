resource "random_password" "sentry_db_username" {
  length  = 16
  special = false
}

resource "random_password" "sentry_db_password" {
  length  = 16
  special = false
}

resource "random_password" "sentry_secret_key" {
  length  = 32
  special = true

  override_special = "!@#$%&*()-_=+<>:?"
}

resource "random_password" "sentry_admin_password" {
  length  = 16
  special = true

  override_special = "!@#$%&*()-_=+<>:?"
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "sentry-db-credentials"
    namespace = kubernetes_namespace.sentry.metadata[0].name
  }

  data = {
    username = random_password.sentry_db_username.result
    password = random_password.sentry_db_password.result
  }
}


