# Backing Valkey for fn-redis (RedisStreamSource). There is no shared/central
# Valkey in the cluster (iac/valkey-operator is a placeholder); every consumer
# runs its own release from the valkey.io Helm chart. This mirrors
# iac/n8n/valkey.tf (unauthenticated standalone, port 6379).

resource "helm_release" "test_valkey" {
  count = var.enable_tests.redis ? 1 : 0

  name      = "valkey"
  namespace = local.test_ns

  repository = "https://valkey.io/valkey-helm/"
  chart      = "valkey"
  version    = "0.10.0"

  timeout = 300

  set = [
    { name = "metrics.enabled", value = "true" },
    { name = "metrics.serviceMonitor.enabled", value = "true" },
  ]
}
