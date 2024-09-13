resource "random_password" "api_key" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_manifest" "api_key_auth_plugin_middleware" {
  count = var.do_enable_api_key_auth ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "${var.name}-api-key-auth"
      namespace = var.namespace
    }

    spec = {
      plugin = {
        api-key-auth = {
          authenticationHeader     = "true"
          authenticationheaderName = "X-API-KEY"
          bearerHeader             = "true"
          bearerHeaderName         = "Authorization"
          keys = [
            random_password.api_key.result,
          ]
          removeHeadersOnSuccess = "true"
        }
      }
    }
  }
}
