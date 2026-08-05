locals {
  traefik_dashboard_domain = "traefik.${var.server_base_domain}"
  traefik_dashboard_port   = 9000
}

resource "kubernetes_namespace" "traefik_dashboard" {
  metadata {
    name = "traefik-dashboard"
  }
}

module "traefik_dashboard_ingress" {
  source = "../modules/ingress"

  name        = "traefik-dashboard"
  namespace   = kubernetes_namespace.traefik_dashboard.metadata[0].name
  domain      = local.traefik_dashboard_domain
  target_port = local.traefik_dashboard_port

  external_name = var.k3s_ip_address

  priority = 900

  auth_mode           = "oidc-interactive"
  keycloak_auth_realm = "master"

  extra_middlewares = [{
    name      = kubernetes_manifest.traefik_dashboard_add_prefix_middleware.manifest.metadata.name
    namespace = kubernetes_manifest.traefik_dashboard_add_prefix_middleware.manifest.metadata.namespace
  }]
}

# api and ping reuse the dashboard's keycloak-auth middleware (single client + plugin
# Secret) so the session cookie set on /dashboard is valid for /api and /ping too.
# Per-route middlewares would each generate their own Secret/client and the cookie
# couldn't be decrypted cross-route, causing 401s on the dashboard's API calls.
module "traefik_dashboard_api_ingress" {
  source = "../modules/ingress"

  name        = "traefik-dashboard-api"
  namespace   = kubernetes_namespace.traefik_dashboard.metadata[0].name
  domain      = local.traefik_dashboard_domain
  path        = "api"
  target_port = local.traefik_dashboard_port

  external_name = var.k3s_ip_address

  priority = 1000

  extra_middlewares = [{
    name      = module.traefik_dashboard_ingress.auth_interactive_middleware_name
    namespace = module.traefik_dashboard_ingress.auth_interactive_middleware_namespace
  }]
}

module "traefik_dashboard_ping_ingress" {
  source = "../modules/ingress"

  name        = "traefik-dashboard-ping"
  namespace   = kubernetes_namespace.traefik_dashboard.metadata[0].name
  domain      = local.traefik_dashboard_domain
  path        = "ping"
  target_port = local.traefik_dashboard_port

  external_name = var.k3s_ip_address

  priority = 1000

  extra_middlewares = [{
    name      = module.traefik_dashboard_ingress.auth_interactive_middleware_name
    namespace = module.traefik_dashboard_ingress.auth_interactive_middleware_namespace
  }]
}

resource "kubernetes_manifest" "traefik_dashboard_add_prefix_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "traefik-dashboard-add-prefix"
      namespace = kubernetes_namespace.traefik_dashboard.metadata[0].name
    }

    spec = {
      addPrefix = {
        prefix = "/dashboard"
      }
    }
  }
}
