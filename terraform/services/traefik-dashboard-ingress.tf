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

  do_enable_keycloak_auth     = true
  is_keycloak_auth_admin_mode = true

  extra_middlewares = [{
    name      = kubernetes_manifest.traefik_dashboard_add_prefix_middleware.manifest.metadata.name
    namespace = kubernetes_manifest.traefik_dashboard_add_prefix_middleware.manifest.metadata.namespace
  }]
}

module "traefik_dashboard_api_ingress" {
  source = "../modules/ingress"

  name        = "traefik-dashboard-api"
  namespace   = kubernetes_namespace.traefik_dashboard.metadata[0].name
  domain      = local.traefik_dashboard_domain
  path        = "api"
  target_port = local.traefik_dashboard_port

  external_name = var.k3s_ip_address

  priority = 1000

  do_enable_keycloak_auth     = true
  is_keycloak_auth_admin_mode = true
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
