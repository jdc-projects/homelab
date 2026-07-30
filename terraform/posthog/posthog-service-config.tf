# Per-service ConfigMaps and Secrets for PostHog services that need
# configuration beyond what the shared posthog-env ConfigMap and
# posthog-secrets Secret provide.

# ==================== ConfigMaps ====================

locals {
  node_service_modes = {
    ingestion-general        = "ingestion-v2-combined"
    ingestion-sessionreplay  = "recordings-blob-ingestion-v2"
    recording-api            = "recording-api"
    ingestion-error-tracking = "ingestion-errortracking"
    ingestion-logs           = "ingestion-logs"
    ingestion-traces         = "ingestion-traces"
  }
}

resource "kubernetes_config_map" "node_service_config" {
  for_each = local.node_service_modes

  metadata {
    name      = "${each.key}-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    PLUGIN_SERVER_MODE = each.value
  }
}

resource "kubernetes_config_map" "capture_config" {
  metadata {
    name      = "capture-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    ADDRESS                                                  = "0.0.0.0:3000"
    KAFKA_TOPIC                                              = "events_plugin_ingestion"
    CAPTURE_MODE                                             = "events"
    RUST_LOG                                                 = "info,rdkafka=warn"
    CAPTURE_V1_SINKS                                         = "msk"
    CAPTURE_V1_SINK_MSK_KAFKA_HOSTS                          = "kafka:9092"
    CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_MAIN                     = "events_plugin_ingestion"
    CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_HISTORICAL               = "events_plugin_ingestion_historical"
    CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_OVERFLOW                 = "events_plugin_ingestion_overflow"
    CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_DLQ                      = "events_plugin_ingestion_dlq"
    CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_EXCEPTION                = "ingestion-errortracking-main"
    CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_HEATMAP                  = "heatmaps_ingestion"
    CAPTURE_V1_SINK_MSK_KAFKA_TOPIC_CLIENT_INGESTION_WARNING = "ingestion-clientwarnings-main-1"
  }
}

resource "kubernetes_config_map" "replay_capture_config" {
  metadata {
    name      = "replay-capture-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    ADDRESS      = "0.0.0.0:3000"
    KAFKA_TOPIC  = "session_recording_snapshot_item_events"
    CAPTURE_MODE = "recordings"
  }
}

resource "kubernetes_config_map" "capture_ai_config" {
  metadata {
    name      = "capture-ai-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    ADDRESS        = "0.0.0.0:3000"
    KAFKA_TOPIC    = "ai_events_ingestion"
    CAPTURE_MODE   = "events"
    RUST_LOG       = "info,rdkafka=warn"
    AI_S3_BUCKET   = "ai-blobs"
    AI_S3_PREFIX   = "llma/"
    AI_S3_ENDPOINT = "http://${local.rustfs_svc}:9000"
    AI_S3_REGION   = "us-east-1"
  }
}

resource "kubernetes_config_map" "capture_logs_config" {
  metadata {
    name      = "capture-logs-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    BIND_HOST           = "0.0.0.0"
    BIND_PORT           = "4318"
    RUST_LOG            = "info,rdkafka=warn"
    RUST_BACKTRACE      = "1"
    KAFKA_TOPIC         = "logs_ingestion"
    KAFKA_METRICS_TOPIC = "metrics_ingestion"
  }
}

resource "kubernetes_config_map" "property_defs_config" {
  metadata {
    name      = "property-defs-rs-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    SKIP_WRITES = "false"
    SKIP_READS  = "false"
    FILTER_MODE = "opt-out"
  }
}

resource "kubernetes_config_map" "feature_flags_config" {
  metadata {
    name      = "feature-flags-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    ADDRESS         = "0.0.0.0:3001"
    RUST_LOG        = "info"
    MAXMIND_DB_PATH = "/share/GeoLite2-City.mmdb"
  }
}

resource "kubernetes_config_map" "personhog_replica_config" {
  metadata {
    name      = "personhog-replica-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    GRPC_ADDRESS = "0.0.0.0:50051"
    RUST_LOG     = "info"
    METRICS_PORT = "9100"
  }
}

resource "kubernetes_config_map" "personhog_router_config" {
  metadata {
    name      = "personhog-router-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    GRPC_ADDRESS       = "0.0.0.0:50052"
    REPLICA_URL        = "http://personhog-replica:50051"
    BACKEND_TIMEOUT_MS = "5000"
    RUST_LOG           = "info"
    METRICS_PORT       = "9101"
  }
}

resource "kubernetes_config_map" "hypercache_config" {
  metadata {
    name      = "hypercache-server-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    ADDRESS  = "0.0.0.0:3002"
    RUST_LOG = "info"
  }
}

resource "kubernetes_config_map" "cyclotron_janitor_config" {
  metadata {
    name      = "cyclotron-janitor-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    KAFKA_TOPIC = "clickhouse_app_metrics2"
  }
}

resource "kubernetes_config_map" "cymbal_config" {
  metadata {
    name      = "cymbal-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    OBJECT_STORAGE_BUCKET           = "posthog"
    OBJECT_STORAGE_ENDPOINT         = "http://${local.rustfs_rec_svc}:9000"
    OBJECT_STORAGE_FORCE_PATH_STYLE = "true"
    BIND_HOST                       = "0.0.0.0"
    BIND_PORT                       = "3302"
    ISSUE_BUCKETS_REDIS_URL         = "redis://valkey:6379/"
    MAXMIND_DB_PATH                 = "/share/GeoLite2-City.mmdb"
    RUST_LOG                        = "info"
  }
}

resource "kubernetes_config_map" "web_config" {
  metadata {
    name      = "web-config"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    HOST_BIND         = "0.0.0.0"
    OIDC_OP_URL       = data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url
    OIDC_CLIENT_ID    = keycloak_openid_client.posthog.client_id
    EMAIL_HOST        = var.smtp_host
    EMAIL_PORT        = var.smtp_port
    EMAIL_USE_SSL     = "true"
    EMAIL_USE_TLS     = "false"
    EMAIL_DEFAULT_FROM = "posthog@${var.server_base_domain}"
    EMAIL_HOST_USER   = var.smtp_username
  }
}

# ==================== Secrets ====================

resource "kubernetes_secret" "capture_logs_secrets" {
  metadata {
    name      = "capture-logs-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    JWT_SECRET = random_id.posthog_secret_key.hex
  }
}

resource "kubernetes_secret" "livestream_secrets" {
  metadata {
    name      = "livestream-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    LIVESTREAM_JWT_SECRET = random_id.posthog_secret_key.hex
  }
}

resource "kubernetes_secret" "feature_flags_secrets" {
  metadata {
    name      = "feature-flags-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    WRITE_DATABASE_URL         = local.database_url
    READ_DATABASE_URL          = local.database_url
    PERSONS_WRITE_DATABASE_URL = local.database_url
    PERSONS_READ_DATABASE_URL  = local.database_url
  }
}

resource "kubernetes_secret" "cyclotron_janitor_secrets" {
  metadata {
    name      = "cyclotron-janitor-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    DATABASE_URL = "${local.pg_base}/cyclotron"
  }
}

resource "kubernetes_secret" "cymbal_secrets" {
  metadata {
    name      = "cymbal-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    OBJECT_STORAGE_ACCESS_KEY_ID     = random_password.rustfs_recordings_username.result
    OBJECT_STORAGE_SECRET_ACCESS_KEY = random_password.rustfs_recordings_password.result
    PERSONS_URL                      = local.database_url
  }
}

resource "kubernetes_secret" "capture_ai_secrets" {
  metadata {
    name      = "capture-ai-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    AI_S3_ACCESS_KEY_ID     = random_password.rustfs_primary_username.result
    AI_S3_SECRET_ACCESS_KEY = random_password.rustfs_primary_password.result
  }
}

resource "kubernetes_secret" "browserless_secrets" {
  metadata {
    name      = "browserless-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    TOKEN = random_password.browserless_token.result
  }
}

resource "kubernetes_secret" "rustfs_provision_secrets" {
  metadata {
    name      = "rustfs-provision-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    RUSTFS_ACCESS_KEY = random_password.rustfs_primary_username.result
    RUSTFS_SECRET_KEY = random_password.rustfs_primary_password.result
  }
}

resource "kubernetes_secret" "rustfs_recordings_provision_secrets" {
  metadata {
    name      = "rustfs-recordings-provision-secrets"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }

  data = {
    RUSTFS_ACCESS_KEY = random_password.rustfs_recordings_username.result
    RUSTFS_SECRET_KEY = random_password.rustfs_recordings_password.result
  }
}
