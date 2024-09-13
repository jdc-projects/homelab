module "whoami_ingress" {
  source = "../modules/ingress"

  name        = "whoami"
  namespace   = kubernetes_namespace.whoami.metadata[0].name
  domain      = "whoami.${var.server_base_domain}"
  target_port = 80
  selector = {
    app = "whoami"
  }

  do_enable_keycloak_auth = true
}

module "traefik_dashboard_ingress" {
  source = "../modules/ingress"

  name        = "traefik-dashboard"
  namespace   = kubernetes_namespace.whoami.metadata[0].name
  domain      = "test.${var.server_base_domain}"
  target_port = 9000

  external_name = "192.168.1.190"

  do_enable_keycloak_auth = true
  is_keycloak_auth_admin_mode = true

  # extra_middlewares = [{
  #   name = kubernetes_manifest.traefik_dashboard_add_prefix_middleware.manifest.metadata.name
  #   namespace = kubernetes_manifest.traefik_dashboard_add_prefix_middleware.manifest.metadata.namespace
  # }]
}

resource "kubernetes_manifest" "traefik_dashboard_add_prefix_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "traefik-dashboard-add-prefix"
      namespace = kubernetes_namespace.whoami.metadata[0].name
    }

    spec = {
      addPrefix = {
        prefix = "/dashboard"
      }
    }
  }
}

