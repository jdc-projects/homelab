resource "random_password" "sentry_db_password" {
  length  = 32
  special = false
}

resource "random_password" "sentry_admin_password" {
  length  = 32
  special = false
}

resource "random_password" "rustfs_username" {
  length  = 16
  special = false
  upper   = false
}

resource "random_password" "rustfs_password" {
  length  = 32
  special = false
}

# Credentials consumed by the CNPG Cluster (bootstrap.initdb.secret) and by the
# Sentry chart (externalPostgresql.existingSecret, key "password").
resource "kubernetes_secret" "sentry_db_credentials" {
  metadata {
    name      = "sentry-db-credentials"
    namespace = local.ns
  }

  data = {
    username = "sentry"
    password = random_password.sentry_db_password.result
  }
}

# RustFS credentials, consumed two ways:
#  - env_from in the mc bucket-provisioning Job (RUSTFS_ACCESS_KEY / RUSTFS_SECRET_KEY).
#  - the Sentry chart's filestore.s3.existingSecret (keys s3-access-key-id /
#    s3-secret-access-key, the chart's defaults).
resource "kubernetes_secret" "sentry_rustfs" {
  metadata {
    name      = "sentry-rustfs"
    namespace = local.ns
  }

  data = {
    RUSTFS_ACCESS_KEY    = random_password.rustfs_username.result
    RUSTFS_SECRET_KEY    = random_password.rustfs_password.result
    s3-access-key-id     = random_password.rustfs_username.result
    s3-secret-access-key = random_password.rustfs_password.result
  }
}

# Shared application secret bag. Consumed by:
#  - user.existingSecret           (admin-password)  -> db-init createuser
#  - mail.existingSecret           (mail-password)
#  - sentry.web.existingSecretEnv  (OIDC_CLIENT_SECRET) -> sentry.conf.py OIDC plugin
resource "kubernetes_secret" "sentry_secrets" {
  metadata {
    name      = "sentry-secrets"
    namespace = local.ns
  }

  data = {
    admin-password     = random_password.sentry_admin_password.result
    mail-password      = var.smtp_password
    OIDC_CLIENT_SECRET = random_password.sentry_oidc_client_secret.result
  }
}
