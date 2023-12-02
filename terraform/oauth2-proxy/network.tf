resource "kubernetes_manifest" "forward_auth_headers_ingress" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "forward-auth-headers"
      namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name
    }

    spec = {
      entryPoints = ["websecure"]

      routes = [{
        kind  = "Rule"
        match = "Host(`admin.${var.server_base_domain}`) && PathPrefix(`/oauth2/`)"
        services = [{
          name      = helm_release.oauth2_proxy.name
          namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name
          port      = "80"
        }]
        middlewares = [{
          name      = kubernetes_manifest.oauth2_proxy_headers_middleware.manifest["metadata"].name
          namespace = kubernetes_manifest.oauth2_proxy_headers_middleware.manifest["metadata"].namespace
        }]
      }]
    }
  }
}
