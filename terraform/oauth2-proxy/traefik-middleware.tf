resource "kubernetes_manifest" "oauth2_proxy_headers_middleware" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "oauth2-proxy-headers"
      namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name
    }

    spec = {
      headers = {
        sslRedirect          = "true"
        stsSeconds           = "315360000"
        browserXssFilter     = "true"
        contentTypeNosniff   = "true"
        forceSTSHeader       = "true"
        sslHost              = "${var.server_base_domain}"
        stsIncludeSubdomains = "true"
        stsPreload           = "true"
        frameDeny            = "true"
      }
    }
  }
}

resource "kubernetes_manifest" "oauth2_proxy_redirect_middleware" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "oauth2-proxy-redirect"
      namespace = kubernetes_manifest.oauth2_proxy_headers_middleware.manifest["metadata"].namespace
    }

    spec = {
      forwardAuth = {
        address            = "http://oauth2-proxy.${kubernetes_namespace.oauth2_proxy.metadata[0].name}"
        trustForwardHeader = "true"
        authResponseHeaders = [
          "X-Auth-Request-Access-Token",
          "Authorization"
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "oauth2_proxy_wo_redirect_middleware" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "oauth2-proxy-wo-redirect"
      namespace = kubernetes_manifest.oauth2_proxy_headers_middleware.manifest["metadata"].namespace
    }

    spec = {
      forwardAuth = {
        address            = "http://oauth2-proxy.${kubernetes_namespace.oauth2_proxy.metadata[0].name}"
        trustForwardHeader = "true"
        authResponseHeaders = [
          "X-Auth-Request-Access-Token",
          "Authorization"
        ]
      }
    }
  }
}
