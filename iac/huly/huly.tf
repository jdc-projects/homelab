locals {
  # ECK generates the elastic password in the elastic-es-elastic-user Secret.
  # We read it via a data source (see elasticsearch.tf) after a null_resource
  # polls for the Secret's existence. URL-embedded basic auth works with the
  # ES 7.x JS client Huly uses.
  es_url = "http://elastic:${data.kubernetes_secret.es_elastic_user.data["elastic"]}@elastic-es-http.${kubernetes_namespace.huly.metadata[0].name}.svc:9200"

  # CNPG RW service - matches the cluster name in postgres.tf.
  db_url = "postgresql://${random_password.huly_db_username.result}:${random_password.huly_db_password.result}@huly-db-rw.${kubernetes_namespace.huly.metadata[0].name}.svc:5432/huly"

  # In-cluster rustfs - chart's STORAGE_CONFIG format is `<provider>|<endpoint>?<query>`.
  # Uses the `minio` provider (not `s3`) so the adapter defaults to path-style
  # addressing (http://host:9000/bucket). The `s3` provider uses virtual-hosted-
  # style (<bucket>.<host>) which requires wildcard DNS that k8s doesn't provide.
  # Endpoint is bare host:port (no http:// prefix) per the minio provider format.
  storage_config = "minio|rustfs-svc.${kubernetes_namespace.huly.metadata[0].name}.svc:9000?accessKey=${random_password.rustfs_root_username.result}&secretKey=${random_password.rustfs_root_password.result}&rootBucket=${local.rustfs_bucket_name}"
}

# Huly helm release - oci://ghcr.io/hcengineering/charts/huly
#
# We disable bundled cockroach/redpanda/elastic/minio and point at the
# cluster-native equivalents (CNPG Postgres, Strimzi Kafka, ECK ES, rustfs).
# Huly's @hcengineering/postgres driver is Postgres-native (PL/pgSQL
# migrations, JSONB ops CRDB only partially supports) - confirmed via source.
#
# Chart ingress is OFF - we use modules/ingress (Traefik IngressRoutes) for
# routing, see ingress.tf. This is the honest value: no chart-managed Ingress
# resources exist. The chart's ConfigMap then derives http://ws:// URLs
# (its templating couples URL scheme with ingress.enabled), so a small
# post-renderer (post-renderer.sh) rewrites them to https/wss before helm
# applies. The same post-renderer also adds the OTel inject annotation to
# each chart-rendered Deployment - see instrumentation.tf.
resource "helm_release" "huly" {
  name      = "huly"
  namespace = kubernetes_namespace.huly.metadata[0].name

  repository = "oci://ghcr.io/hcengineering/charts"
  chart      = "huly"
  version    = "0.1.0"

  timeout = 600

  # Patches two chart limitations: see post-renderer.sh.
  postrender = {
    binary_path = "${path.module}/post-renderer.sh"
    args        = [local.huly_domain]
  }

  set = [
    # --- Identity ---
    { name = "domain", value = local.huly_domain },
    { name = "hulyVersion", value = "v0.7.432" },
    # No chart-managed ingress - we use Traefik IngressRoutes (see ingress.tf).
    { name = "ingress.enabled", value = "false" },

    # --- External infra: bundled chart deps OFF, point at cluster services ---
    { name = "cockroach.enabled", value = "false" },
    { name = "redpanda.enabled", value = "false" },
    { name = "elastic.enabled", value = "false" },
    { name = "minio.enabled", value = "false" },
    { name = "storage.type", value = "s3" },

    { name = "external.redpanda", value = "kafka.${kubernetes_namespace.huly.metadata[0].name}.svc:9092" },
    { name = "external.elastic", value = local.es_url },

    # --- S3 storage (rustfs) ---
    { name = "storage.s3.endpoint", value = "http://rustfs-svc.${kubernetes_namespace.huly.metadata[0].name}.svc:9000" },
    { name = "storage.s3.region", value = "us-east-1" },
    { name = "storage.s3.rootBucket", value = local.rustfs_bucket_name },

    # --- Auth: Keycloak OIDC ---
    # `disableSignup=false` is required so OIDC auto-provisioning works for
    # Keycloak users on first login (with disableSignup=true, Huly rejects
    # OIDC logins when no Huly account exists — chicken-and-egg). The
    # chart's disableSignup flag also opens the `signUp` RPC at
    # POST /_accounts/ to anyone (no email confirmation; the chart doesn't
    # set MAIL_URL). We close that hole at the ingress layer instead —
    # see ingress.tf's auth gating comment. Do NOT remove the gateway auth
    # on the accounts route without an alternative (DB bootstrap, source
    # fork, etc.).
    { name = "auth.oidc.clientId", value = keycloak_openid_client.huly.client_id },
    { name = "auth.oidc.issuer", value = data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url },
    { name = "auth.disableSignup", value = "false" },

    # --- PVC storage class for any remaining bundled deps ---
    { name = "cockroach.storageClassName", value = "openebs-zfs-localpv-random" },
    { name = "elastic.storageClassName", value = "openebs-zfs-localpv-bulk" },
    { name = "redpanda.storageClassName", value = "openebs-zfs-localpv-bulk" },
    { name = "minio.storageClassName", value = "openebs-zfs-localpv-bulk" },

    # --- App settings ---
    { name = "appSettings.title", value = "Huly" },
  ]

  set_sensitive = [
    { name = "secrets.crDbUrl", value = local.db_url },
    { name = "secrets.storageConfig", value = local.storage_config },
    { name = "auth.oidc.clientSecret", value = random_password.keycloak_client_secret.result },

    # Root creds for rustfs - the chart's storage.s3.* values reference these.
    { name = "storage.s3.accessKey", value = random_password.rustfs_root_username.result },
    { name = "storage.s3.secretKey", value = random_password.rustfs_root_password.result },
  ]

  depends_on = [
    kubernetes_manifest.huly_instrumentation,
    kubernetes_manifest.elasticsearch,
    kubernetes_manifest.huly_db,
    kubernetes_manifest.kafka,
    kubernetes_service.kafka,
    helm_release.rustfs,
  ]
}
