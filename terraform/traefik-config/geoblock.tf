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
          silentStartUp             = "true"
          allowLocalRequests        = "true"
          logLocalRequests          = "false"
          logAllowedRequests        = "false"
          logApiRequests            = "false"
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
          allowedIPAddresses = [
            "100.64.0.0/10", # tailscale: https://tailscale.com/kb/1015/100.x-addresses
          ]
        }
      }
    }
  }
}
