data "cloudflare_ip_ranges" "cloudflare" {}

resource "kubernetes_manifest" "crowdsec_bouncer_traefik_plugin_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "crowdsec-bouncer"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }

    spec = {
      plugin = {
        crowdsec-bouncer = {
          Enabled               = "true"
          LogLevel              = "INFO"
          CrowdsecMode          = "live"
          CrowdsecAppsecEnabled = "true"
          CrowdsecAppsecHost    = "${data.terraform_remote_state.crowdsec.outputs.crowdsec_helm_release_name}-appsec-service.${data.terraform_remote_state.crowdsec.outputs.crowdsec_namespace}:7422"
          CrowdsecLapiScheme    = "http"
          CrowdsecLapiHost      = "${data.terraform_remote_state.crowdsec.outputs.crowdsec_helm_release_name}-service.${data.terraform_remote_state.crowdsec.outputs.crowdsec_namespace}:8080"
          CrowdsecLapiKey       = data.terraform_remote_state.crowdsec.outputs.traefik_api_key
          ClientTrustedIPs = [
            "192.168.100.0/24",
          ]
          ForwardedHeadersTrustedIPs = flatten(data.cloudflare_ip_ranges.cloudflare.cidr_blocks) # flatten is required to prevent an error for some reason...
        }
      }
    }
  }
}
