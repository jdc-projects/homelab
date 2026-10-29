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
          CrowdsecMode          = "stream"
          CrowdsecAppsecEnabled = "true"
          CrowdsecAppsecHost    = "${data.terraform_remote_state.crowdsec.outputs.crowdsec_helm_release_name}-appsec-service.${data.terraform_remote_state.crowdsec.outputs.crowdsec_namespace}:7422"
          CrowdsecLapiScheme    = "http"
          CrowdsecLapiHost      = "${data.terraform_remote_state.crowdsec.outputs.crowdsec_helm_release_name}-service.${data.terraform_remote_state.crowdsec.outputs.crowdsec_namespace}:8080"
          CrowdsecLapiKey       = data.terraform_remote_state.crowdsec.outputs.traefik_api_key
          # Fail fast when LAPI/AppSec cannot answer. The plugin default 10s let
          # a wedged appsec engine stall every edge request for a full 10s
          # before the fail-closed 403 (reproduced 2026-10-29 during an OCIS
          # upload). Baseline bouncer overhead is <100ms, so 5s is generous
          # headroom. Deliberately still fail-closed (no fail-open).
          HTTPTimeoutSeconds = "5"
          ClientTrustedIPs = [
            "192.168.100.0/24",
          ]
          ForwardedHeadersTrustedIPs = flatten(data.cloudflare_ip_ranges.cloudflare.ipv4_cidrs) # flatten is required to prevent an error for some reason...
        }
      }
    }
  }
}

resource "kubernetes_manifest" "crowdsec_bouncer_without_appsec_traefik_plugin_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "crowdsec-bouncer-without-appsec"
      namespace = data.terraform_remote_state.traefik.outputs.traefik_namespace
    }

    spec = {
      plugin = {
        crowdsec-bouncer = {
          Enabled               = "true"
          LogLevel              = "INFO"
          CrowdsecMode          = "stream"
          CrowdsecAppsecEnabled = "false"
          CrowdsecLapiScheme    = "http"
          CrowdsecLapiHost      = "${data.terraform_remote_state.crowdsec.outputs.crowdsec_helm_release_name}-service.${data.terraform_remote_state.crowdsec.outputs.crowdsec_namespace}:8080"
          CrowdsecLapiKey       = data.terraform_remote_state.crowdsec.outputs.traefik_api_key
          # Must match the crowdsec-bouncer middleware above - the plugin only
          # honours one effective instance for shared parameters.
          HTTPTimeoutSeconds = "5"
          ClientTrustedIPs = [
            "192.168.100.0/24",
          ]
          ForwardedHeadersTrustedIPs = flatten(data.cloudflare_ip_ranges.cloudflare.ipv4_cidrs) # flatten is required to prevent an error for some reason...
        }
      }
    }
  }
}
