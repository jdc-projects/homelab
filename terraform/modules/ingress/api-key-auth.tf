resource "random_password" "api_key" {
  length  = 50
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_manifest" "api_key_plugin_middleware" {
  count = var.do_enable_api_key_auth ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "api-key"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }

    spec = {
      plugin = {
        api-key = {
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
