resource "kubernetes_service" "traefik_forward_auth" {
  metadata {
    name      = "traefik-forward-auth"
    namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
  }

  spec {
    selector = {
      app = "traefik-forward-auth"
    }

    port {
      port        = "80"
      target_port = kubernetes_config_map.traefik_forward_auth_env.data.PORT
    }
  }
}

resource "kubernetes_manifest" "traefik_forward_auth_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "traefik-forward-auth"
      namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`traefik-forward-auth.${var.server_base_domain}`)"
        services = [{
          name      = kubernetes_service.traefik_forward_auth.metadata[0].name
          namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
          port      = kubernetes_service.traefik_forward_auth.spec[0].port[0].port
        }]
      }]
    }
  }
}

resource "kubernetes_manifest" "traefik_forward_auth_middleware" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "traefik-forward-auth"
      namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
    }

    spec = {
      forwardAuth = {
        address             = "https://traefik-forward-auth.${var.server_base_domain}${kubernetes_config_map.traefik_forward_auth_env.data.URL_PATH}"
        authResponseHeaders = ["X-Forwarded-User"]
        trustForwardHeader  = "true"
      }
    }
  }
}
