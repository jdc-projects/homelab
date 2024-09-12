resource "kubernetes_manifest" "geoblock_traefik_plugin_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "geoblock"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }

    spec = {
      plugin = {
        geoblock = {
          silentStartUp             = "false"
          allowLocalRequests        = "true"
          logLocalRequests          = "true"
          logAllowedRequests        = "true"
          logApiRequests            = "true"
          api                       = "https://get.geojs.io/v1/ip/country/{ip}"
          apiTimeoutMs              = 750
          cacheSize                 = 15
          forceMonthlyUpdate        = "true"
          allowUnknownCountries     = "false"
          unknownCountryApiResponse = "nil"
          blackListMode             = "false"
          addCountryHeader          = "false"
          countries = [
            "GB",
          ]
        }
      }
    }
  }
}
