data "cloudflare_ip_ranges" "cloudflare" {}

resource "kubernetes_manifest" "crowdsec_bouncer_traefik_plugin_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "crowdsec-bouncer-traefik-plugin"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }

    spec = {
      plugin = {
        crowdsec-bouncer-traefik-plugin = {
          Enabled      = "true"
          LogLevel     = "INFO"
          CrowdsecMode = "live"
          # currently the helm chart doesn't support appsec - see https://github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin/issues/150 - enable when it does
          CrowdsecAppsecEnabled = "false"
          # CrowdsecAppsecHost = "crowdsec:7422" # *****
          CrowdsecLapiScheme         = "http"
          CrowdsecLapiHost           = "${data.terraform_remote_state.crowdsec.outputs.crowdsec_helm_release_name}-service:8080" # *****
          CrowdsecLapiKey            = data.terraform_remote_state.crowdsec.outputs.traefik_api_key
          ClientTrustedIPs           = [] # wildcard for local IPs?
          ForwardedHeadersTrustedIPs = data.cloudflare_ip_ranges.cloudflare.cidr_blocks
        }
      }
    }
  }
}
