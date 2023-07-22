resource "kubernetes_service" "traefik_forward_auth_test" {
  metadata {
    name      = "traefik-forward-auth-test"
    namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
  }

  spec {
    selector = {
      app = "traefik-forward-auth-test"
    }

    port {
      port        = "80"
      target_port = "80"
    }
  }
}

resource "kubernetes_manifest" "traefik_forward_auth_test_ingress" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "traefik-forward-auth-test"
      namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`admin.${var.server_base_domain}`) && PathPrefix(`/test`)"
        services = [{
          name      = kubernetes_service.traefik_forward_auth_test.metadata[0].name
          namespace = kubernetes_namespace.traefik_forward_auth.metadata[0].name
          port      = kubernetes_service.traefik_forward_auth_test.spec[0].port[0].port
        }]
        middlewares = [{
          name      = "traefik-forward-auth"
          namespace = "traefik-forward-auth"
        }]
      }]
    }
  }
}
