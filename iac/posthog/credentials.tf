resource "random_id" "posthog_secret_key" {
  byte_length = 50
}

resource "random_id" "encryption_salt_key" {
  byte_length = 16
}

resource "random_password" "posthog_db_password" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "posthog_db_credentials" {
  metadata {
    name      = "posthog-db-credentials"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    username = "posthog"
    password = random_password.posthog_db_password.result
  }
}

resource "random_password" "rustfs_primary_username" {
  length  = 16
  special = false
  upper   = false
}

resource "random_password" "rustfs_primary_password" {
  length  = 32
  special = false
}

resource "random_password" "rustfs_recordings_username" {
  length  = 16
  special = false
  upper   = false
}

resource "random_password" "rustfs_recordings_password" {
  length  = 32
  special = false
}

resource "random_password" "browserless_token" {
  length  = 32
  special = false
}

resource "tls_private_key" "posthog_oidc" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "kubernetes_secret" "posthog_secrets" {
  metadata {
    name      = "posthog-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    SECRET_KEY                                = random_id.posthog_secret_key.hex
    ENCRYPTION_SALT_KEYS                      = random_id.encryption_salt_key.hex
    DATABASE_URL                              = local.database_url
    PERSONS_DATABASE_URL                      = local.database_url
    BEHAVIORAL_COHORTS_DATABASE_URL           = local.database_url
    CYCLOTRON_DATABASE_URL                    = local.database_url
    CYCLOTRON_NODE_DATABASE_URL               = "${local.pg_base}/cyclotron_node"
    CYCLOTRON_JANITOR_DB_URL                  = "${local.pg_base}/cyclotron"
    PRIMARY_DATABASE_URL                      = local.database_url
    PGPASSWORD                                = random_password.posthog_db_password.result
    OBJECT_STORAGE_ACCESS_KEY_ID              = random_password.rustfs_primary_username.result
    OBJECT_STORAGE_SECRET_ACCESS_KEY          = random_password.rustfs_primary_password.result
    SESSION_RECORDING_V2_S3_ACCESS_KEY_ID     = random_password.rustfs_recordings_username.result
    SESSION_RECORDING_V2_S3_SECRET_ACCESS_KEY = random_password.rustfs_recordings_password.result
    BROWSERLESS_CDP_URL                       = "ws://browserless:3000"
    BROWSERLESS_TOKEN                         = random_password.browserless_token.result
    HEATMAP_BROWSERLESS_URL                   = "http://browserless:3000"
    HEATMAP_BROWSERLESS_TOKEN                 = random_password.browserless_token.result
    OIDC_CLIENT_SECRET                        = random_password.posthog_oidc_client_secret.result
    OIDC_RSA_PRIVATE_KEY                      = tls_private_key.posthog_oidc.private_key_pem
    EMAIL_HOST_PASSWORD                       = var.smtp_password
    OPENAI_API_KEY                            = var.openai_api_key != null ? var.openai_api_key : ""
    ANTHROPIC_API_KEY                         = var.anthropic_api_key != null ? var.anthropic_api_key : ""
  }
}
