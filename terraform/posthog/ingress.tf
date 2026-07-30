locals {
  ns = kubernetes_namespace.posthog.metadata[0].name

  # All PostHog ingress routes. Each entry creates one IngressRoute via the
  # shared ingress module. Traefik merges routes by priority — more specific
  # paths get higher numbers.
  ingress_routes = {
    static       = { svc = kubernetes_service.posthog_web.metadata[0].name, port = 8000, path = "static", priority = 101, geoblock = true }
    e            = { svc = kubernetes_service.capture.metadata[0].name, port = 3000, path = "e", priority = 100, geoblock = false }
    i-v0-ai      = { svc = kubernetes_service.capture_ai.metadata[0].name, port = 3000, path = "i/v0/ai", priority = 100, geoblock = false }
    i-v0         = { svc = kubernetes_service.capture.metadata[0].name, port = 3000, path = "i/v0", priority = 90, geoblock = false }
    batch        = { svc = kubernetes_service.capture.metadata[0].name, port = 3000, path = "batch", priority = 100, geoblock = false }
    capture      = { svc = kubernetes_service.capture.metadata[0].name, port = 3000, path = "capture", priority = 100, geoblock = false }
    s            = { svc = kubernetes_service.replay_capture.metadata[0].name, port = 3000, path = "s", priority = 100, geoblock = false }
    i-v1-logs    = { svc = kubernetes_service.capture_logs.metadata[0].name, port = 4318, path = "i/v1/logs", priority = 100, geoblock = false }
    i-v1-traces  = { svc = kubernetes_service.capture_logs.metadata[0].name, port = 4318, path = "i/v1/traces", priority = 100, geoblock = false }
    i-v1-metrics = { svc = kubernetes_service.capture_logs.metadata[0].name, port = 4318, path = "i/v1/metrics", priority = 100, geoblock = false }
    flags        = { svc = kubernetes_service.feature_flags.metadata[0].name, port = 3001, path = "flags", priority = 90, geoblock = false }
    flags-eval   = { svc = kubernetes_service.feature_flags.metadata[0].name, port = 3001, path = "api/feature_flag/local_evaluation", priority = 90, geoblock = false }
    surveys      = { svc = kubernetes_service.hypercache_server.metadata[0].name, port = 3002, path = "surveys", priority = 90, geoblock = false }
    api-surveys  = { svc = kubernetes_service.hypercache_server.metadata[0].name, port = 3002, path = "api/surveys", priority = 90, geoblock = false }
    array        = { svc = kubernetes_service.hypercache_server.metadata[0].name, port = 3002, path = "array", priority = 90, geoblock = false }
    webhooks     = { svc = kubernetes_service.plugins.metadata[0].name, port = 6738, path = "public/webhooks", priority = 90, geoblock = true }
    public-m     = { svc = kubernetes_service.plugins.metadata[0].name, port = 6738, path = "public/m", priority = 90, geoblock = true }
    posthog-obj  = { svc = local.rustfs_svc, port = 9000, path = "posthog", priority = 80, geoblock = true }
    decide       = { svc = kubernetes_service.posthog_web.metadata[0].name, port = 8000, path = "decide", priority = 95, geoblock = false }
    catch-all    = { svc = kubernetes_service.posthog_web.metadata[0].name, port = 8000, path = "", priority = 1, geoblock = true }
  }
}

module "posthog_ingress" {
  for_each = { for k, v in local.ingress_routes : k => v if k != "livestream" }
  source   = "../modules/ingress"

  name                       = "posthog-${each.key}"
  namespace                  = local.ns
  domain                     = local.posthog_domain
  path                       = each.value.path
  priority                   = each.value.priority
  existing_service_name      = each.value.svc
  existing_service_namespace = local.ns
  target_port                = each.value.port

  do_enable_crowdsec_bouncer_appsec = false
  do_enable_geoblock                = each.value.geoblock
}

# Livestream needs StripPrefix to remove /livestream before forwarding.
resource "kubernetes_manifest" "livestream_strip_prefix" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "livestream-strip-prefix"
      namespace = local.ns
    }

    spec = {
      stripPrefix = {
        prefixes = ["/livestream"]
      }
    }
  }
}

module "posthog_livestream_ingress" {
  source = "../modules/ingress"

  name                       = "posthog-livestream"
  namespace                  = local.ns
  domain                     = local.posthog_domain
  path                       = "livestream"
  priority                   = 90
  existing_service_name      = kubernetes_service.livestream.metadata[0].name
  existing_service_namespace = local.ns
  target_port                = 8080

  do_enable_crowdsec_bouncer_appsec = false

  extra_middlewares = [{
    name      = kubernetes_manifest.livestream_strip_prefix.manifest.metadata.name
    namespace = local.ns
  }]
}
