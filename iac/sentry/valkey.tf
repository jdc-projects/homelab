# Dedicated Valkey cache for Sentry.
#
# NOTE: deployed unauthenticated, matching the PostHog module's pattern. The
# valkey.io helm chart uses ACL-based auth (auth.aclUsers), not a simple
# auth.password field; wiring that correctly is deferred to a hardening pass.
# The instance lives in its own namespace behind a dedicated Service, so the
# unauthenticated posture matches the rest of the cluster's caches.
resource "helm_release" "valkey" {
  name      = "valkey"
  namespace = local.ns

  repository = "https://valkey.io/valkey-helm/"
  chart      = "valkey"
  version    = local.valkey_chart_version

  timeout = 300

  set = [
    { name = "resources.requests.cpu", value = "200m" },
    { name = "resources.requests.memory", value = "256Mi" },
    { name = "resources.limits.cpu", value = "500m" },
    { name = "resources.limits.memory", value = "512Mi" },
    { name = "metrics.enabled", value = "true" },
    { name = "metrics.serviceMonitor.enabled", value = "true" },
  ]
}
