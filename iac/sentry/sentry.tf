locals {
  # Chart-created Services (fullnameOverride = "sentry").
  sentry_web_svc    = "sentry-web"
  sentry_relay_svc  = "sentry-relay"
  sentry_web_port   = 9000
  sentry_relay_port = 3000
}

resource "helm_release" "sentry" {
  name       = "sentry"
  repository = "https://sentry-kubernetes.github.io/charts"
  chart      = "sentry"
  version    = local.sentry_chart_version

  namespace = local.ns

  create_namespace = false
  # atomic intentionally false for the first bring-up so a hook failure leaves the
  # release in place for debugging (images/migrations are slow on first install).
  # Flip to true once stable.
  atomic  = false
  timeout = 1200

  values = [<<-YAML
    fullnameOverride: "sentry"

    system:
      url: "https://sentry.${var.server_base_domain}"

    # Initial admin user — created by the db-init hook reading "admin-password"
    # from sentry-secrets.
    user:
      create: true
      email: "${var.admin_email}"
      existingSecret: "sentry-secrets"

    # Custom Sentry image with the sentry-auth-oidc plugin baked in.
    # All other images (snuba/relay/vroom/taskbroker/...) default to
    # getsentry/<component>:<Chart.AppVersion>.
    images:
      sentry:
        repository: "ghcr.io/jdc-projects/sentry-oidc"
        tag: "sentry-26.7.1-oidc-9.1.1"

    # ---- Bring-your-own dependencies (all in-cluster) ----
    postgresql:
      enabled: false
    redis:
      enabled: false
    kafka:
      enabled: false
    ingress:
      enabled: false
    nginx:
      enabled: false
    symbolicator:
      enabled: false
    metrics:
      enabled: false
    pgbouncer:
      enabled: false

    externalPostgresql:
      host: "${local.pg_host}"
      port: 5432
      username: "sentry"
      database: "sentry"
      existingSecret: "sentry-db-credentials"
      existingSecretKeys:
        password: "password"

    externalRedis:
      host: "valkey"
      port: 6379

    externalKafka:
      host: "kafka"
      port: 9092
      security:
        protocol: "PLAINTEXT"
      provisioning:
        enabled: true
        replicationFactor: 1
        numPartitions: 1

    externalClickhouse:
      host: "clickhouse"
      tcpPort: 9000
      httpPort: 8123
      username: "sentry"
      password: ""
      database: "sentry"
      singleNode: true
      clusterName: "sentry"

    filestore:
      backend: "s3"
      s3:
        existingSecret: "sentry-rustfs"
        bucketName: "sentry"
        endpointUrl: "http://${local.rustfs_svc}:9000"
        region_name: "us-east-1"

    mail:
      backend: "smtp"
      host: "${var.smtp_host}"
      port: ${var.smtp_port}
      # SMTP relay is on port 465 (implicit TLS / SMTPS).
      useSsl: true
      username: "${var.smtp_username}"
      from: "sentry@${var.server_base_domain}"
      existingSecret: "sentry-secrets"

    # topicctl (externalKafka.provisioning) owns topic creation on the
    # single-broker Strimzi cluster; stop snuba-init from also trying.
    hooks:
      snubaInit:
        kafka:
          enabled: false

    sentry:
      singleOrganization: true
      web:
        existingSecretEnv: "sentry-secrets"
      # The cluster has no default StorageClass; the chart's taskBroker PVC
      # defaults to "" and never binds. Pin it to the no-backup bulk class —
      # taskbroker queues are ephemeral and excluded from velero backups.
      taskBroker:
        persistence:
          storageClass: "openebs-zfs-localpv-bulk-no-backup"

    # OIDC SSO via the sentry-auth-oidc plugin (installed in the custom image).
    # OIDC_DOMAIN is the Keycloak realm URL; the plugin appends
    # /.well-known/openid-configuration for discovery. OIDC_CLIENT_SECRET is read
    # at runtime from env injected via sentry.web.existingSecretEnv.
    config:
      sentryConfPy: |
        import os
        OIDC_DOMAIN = "${trimsuffix(data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url, "/")}"
        # Display name for the provider. This plugin version sets provider.name =
        # ISSUER (it ignores OIDC_PROVIDER_NAME), and ISSUER is used ONLY for
        # display -- the id_token is decoded without issuer/signature checks, and
        # the OAuth endpoints come from OIDC_DOMAIN's discovery. So overriding
        # ISSUER here is a safe cosmetic rename.
        OIDC_ISSUER = "Keycloak"
        OIDC_CLIENT_ID = "sentry"
        OIDC_CLIENT_SECRET = os.environ.get("OIDC_CLIENT_SECRET", "")
        OIDC_SCOPE = "openid email"
  YAML
  ]

  depends_on = [
    kubernetes_manifest.sentry_db,
    kubernetes_manifest.sentry_db_pooler,
    helm_release.valkey,
    kubernetes_manifest.kafka,
    kubernetes_manifest.kafka_node_pool,
    kubernetes_service.kafka,
    kubernetes_manifest.sentry_clickhouse,
    kubernetes_service.clickhouse,
    kubernetes_job.clickhouse_provision,
    helm_release.rustfs,
    kubernetes_job.rustfs_provision,
    keycloak_openid_client.sentry,
    kubernetes_secret.sentry_db_credentials,
    kubernetes_secret.sentry_secrets,
    kubernetes_secret.sentry_rustfs,
  ]
}
