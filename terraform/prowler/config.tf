resource "kubernetes_config_map" "prowler_env" {
  metadata {
    name      = "prowler"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  data = {
    PROWLER_UI_VERSION       = "stable"
    SITE_URL                 = "https://${local.prowler_domain}"
    API_BASE_URL             = "https://${local.prowler_domain}/api/v1"
    NEXT_PUBLIC_API_DOCS_URL = "https://${local.prowler_domain}/api/v1/docs"
    AUTH_TRUST_HOST          = "true"
    UI_PORT                  = 3000

    PROWLER_API_VERSION = "stable"
    POSTGRES_HOST       = "${kubernetes_manifest.prowler_db.manifest.metadata.name}-rw"
    POSTGRES_PORT       = 5432
    POSTGRES_DB         = kubernetes_manifest.prowler_db.manifest.spec.bootstrap.initdb.database

    VALKEY_HOST = "${helm_release.valkey.name}-primary"
    VALKEY_PORT = 6379
    VALKEY_DB   = 0

    DJANGO_TMP_OUTPUT_DIRECTORY = "/tmp/prowler_api_output"

    DJANGO_FINDINGS_BATCH_SIZE = 1000

    # DJANGO_OUTPUT_S3_AWS_ACCESS_KEY_ID = ""
    # DJANGO_OUTPUT_S3_AWS_DEFAULT_REGION = ""
    # DJANGO_OUTPUT_S3_AWS_OUTPUT_BUCKET = ""

    DJANGO_ALLOWED_HOSTS          = local.prowler_domain
    DJANGO_BIND_ADDRESS           = "0.0.0.0"
    DJANGO_PORT                   = 8080
    DJANGO_DEBUG                  = "False"
    DJANGO_SETTINGS_MODULE        = "config.django.production"
    DJANGO_LOGGING_FORMATTER      = "human_readable"
    DJANGO_LOGGING_LEVEL          = "INFO"
    DJANGO_WORKERS                = 4
    DJANGO_ACCESS_TOKEN_LIFETIME  = 30
    DJANGO_REFRESH_TOKEN_LIFETIME = 1440
    DJANGO_CACHE_MAX_AGE          = 3600
    DJANGO_STALE_WHILE_REVALIDATE = 60
    DJANGO_MANAGE_DB_PARTITIONS   = "True"
  }
}

resource "kubernetes_secret" "prowler_env" {
  metadata {
    name      = "prowler"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  data = {
    AUTH_SECRET = random_bytes.prowler_auth_secret.base64

    POSTGRES_ADMIN_USER     = random_password.prowler_db_superuser_username.result
    POSTGRES_ADMIN_PASSWORD = random_password.prowler_db_superuser_password.result
    POSTGRES_USER           = random_password.prowler_db_username.result
    POSTGRES_PASSWORD       = random_password.prowler_db_password.result

    # DJANGO_OUTPUT_S3_AWS_SECRET_ACCESS_KEY = ""

    DJANGO_TOKEN_SIGNING_KEY         = tls_private_key.prowler_token_signing_key.private_key_pem
    DJANGO_TOKEN_VERIFYING_KEY       = tls_private_key.prowler_token_signing_key.public_key_pem
    DJANGO_SECRETS_ENCRYPTION_KEY    = random_bytes.prowler_secrets_encryption_key.base64
    DJANGO_BROKER_VISIBILITY_TIMEOUT = 86400
    DJANGO_SENTRY_DSN                = ""

    SENTRY_ENVIRONMENT = "local"
    SENTRY_RELEASE     = "local"

    # NEXT_PUBLIC_PROWLER_RELEASE_VERSION="v5.5.0"
  }
}
