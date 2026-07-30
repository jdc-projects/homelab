locals {
  posthog_domain = "posthog.${var.server_base_domain}"
}

resource "kubernetes_config_map" "posthog_env" {
  metadata {
    name      = "posthog-env"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    SITE_URL                           = "https://${local.posthog_domain}"
    DEPLOYMENT                         = "hobby"
    IS_BEHIND_PROXY                    = "true"
    TRUST_ALL_PROXIES                  = "true"
    DISABLE_SECURE_SSL_REDIRECT        = "true"
    KAFKA_HOSTS                        = "kafka:9092"
    REDIS_URL                          = "redis://valkey:6379/"
    CLICKHOUSE_HOST                    = "clickhouse"
    CLICKHOUSE_USER                    = "posthog"
    CLICKHOUSE_DATABASE                = "posthog"
    CLICKHOUSE_SECURE                  = "false"
    CLICKHOUSE_VERIFY                  = "false"
    CLICKHOUSE_LOGS_CLUSTER_HOST       = "clickhouse"
    CLICKHOUSE_LOGS_CLUSTER_SECURE     = "false"
    OBJECT_STORAGE_ENABLED             = "true"
    OBJECT_STORAGE_ENDPOINT            = "http://${local.rustfs_svc}:9000"
    OBJECT_STORAGE_FORCE_PATH_STYLE    = "true"
    OBJECT_STORAGE_PUBLIC_ENDPOINT     = "https://${local.posthog_domain}"
    SESSION_RECORDING_V2_S3_ENDPOINT   = "http://${local.rustfs_rec_svc}:9000"
    SESSION_RECORDING_V2_S3_TIMEOUT_MS = "120000"
    RECORDING_API_URL                  = "http://recording-api:6738"
    PERSONHOG_ADDR                     = "personhog-router:50052"
    PERSONHOG_ENABLED                  = "true"
    FEATURE_FLAGS_SERVICE_URL          = "http://feature-flags:3001"
    CDP_API_URL                        = "http://plugins:6738"
    FLAGS_REDIS_ENABLED                = "false"
    PERSONS_DB_WRITER_URL              = local.database_url
    PERSONS_DB_READER_URL              = local.database_url
    OTEL_SDK_DISABLED                  = "true"
    OPT_OUT_CAPTURE                    = "true"
    SELF_CAPTURE                       = "true"
    PGHOST                             = local.pg_host
    PGUSER                             = "posthog"
    LIVESTREAM_HOST                    = "https://${local.posthog_domain}/livestream"
    POSTHOG_SKIP_MIGRATION_CHECKS      = "1"
    API_QUERIES_PER_TEAM               = "{\"1\": 100}"
    SKIP_ASYNC_MIGRATIONS_SETUP        = "0"
    CDP_REDIS_HOST                     = "valkey"
    CDP_REDIS_PORT                     = "6379"
    COOKIELESS_REDIS_HOST              = "valkey"
    COOKIELESS_REDIS_PORT              = "6379"
    SESSION_RECORDING_API_REDIS_HOST   = "valkey"
    SESSION_RECORDING_API_REDIS_PORT   = "6379"
    LOGS_REDIS_HOST                    = "valkey"
    LOGS_REDIS_PORT                    = "6379"
    LOGS_REDIS_TLS                     = "false"
    TRACES_REDIS_HOST                  = "valkey"
    TRACES_REDIS_PORT                  = "6379"
    TRACES_REDIS_TLS                   = "false"
    REDIS_POOL_MIN_SIZE                = "1"
    TEMPORAL_HOST                      = "temporal"
    TEMPORAL_PORT                      = "7233"
    CELERY_MAX_MEMORY_PER_CHILD        = "1572864"
    WEB_CONCURRENCY                    = "2"
  }
}
