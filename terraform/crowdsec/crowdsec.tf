locals {
  crowdsec_enroll_tags = join(" ", [
    "k3s",
    "homelab",
  ])
}

resource "helm_release" "crowdsec" {
  name = "crowdsec"

  repository = "https://crowdsecurity.github.io/helm-charts"
  chart      = "crowdsec"
  version    = "0.16.0"

  namespace = kubernetes_namespace.crowdsec.metadata[0].name

  timeout = 300

  set {
    name  = "config.config\\.yaml\\.local"
    value = <<-EOF
      api:
        server:
          auto_registration: # Activate if not using TLS for authentication or when using Appsec
            enabled: true
            token: "$${REGISTRATION_TOKEN}" # /!\ Do not modify this variable (auto-generated and handled by the chart)
            allowed_ranges:
              - "10.0.0.8/8"
    EOF
  }

  set_sensitive {
    name  = "secrets.username"
    value = random_password.crowdsec_agent_username.result
  }
  set_sensitive {
    name  = "secrets.password"
    value = random_password.crowdsec_agent_password.result
  }

  set {
    name  = "lapi.env[0].name"
    value = "ENROLL_KEY"
  }
  set_sensitive {
    name  = "lapi.env[0].value"
    value = var.crowdsec_enroll_key
  }
  set {
    name  = "lapi.env[1].name"
    value = "ENROLL_INSTANCE_NAME"
  }
  set {
    name  = "lapi.env[1].value"
    value = "k3s-homelab"
  }
  set {
    name  = "lapi.env[2].name"
    value = "ENROLL_TAGS"
  }
  set {
    name  = "lapi.env[2].value"
    value = local.crowdsec_enroll_tags
  }
  set {
    name  = "lapi.env[3].name"
    value = "BOUNCER_KEY_traefik"
  }
  set_sensitive {
    name  = "lapi.env[3].value"
    value = random_password.traefik_api_key.result
  }
  set_sensitive {
    name  = "lapi.secrets.csLapiSecret"
    value = random_password.crowdsec_lapi_secret.result
  }
  set_sensitive {
    name  = "lapi.secrets.registrationToken"
    value = random_password.crowdsec_registration_token.result
  }

  set {
    name  = "agent.acquisition[0].namespace"
    value = data.terraform_remote_state.traefik.outputs.traefik_namespace
  }
  set {
    name  = "agent.acquisition[0].podName"
    value = "${data.terraform_remote_state.traefik.outputs.traefik_helm_release_name}-*"
  }
  set {
    name  = "agent.acquisition[0].program"
    value = "traefik"
  }

  set {
    name  = "appsec.enabled"
    value = "true"
  }
  set {
    name  = "appsec.acquisitions[0].source"
    value = "appsec"
  }
  set {
    name  = "appsec.acquisitions[0].listen_addr"
    value = "0.0.0.0:7422"
  }
  set {
    name  = "appsec.acquisitions[0].path"
    value = "/"
  }
  set {
    name  = "appsec.acquisitions[0].appsec_config"
    value = "crowdsecurity/custom-appsec-config"
  }
  set {
    name  = "appsec.acquisitions[0].labels.type"
    value = "appsec"
  }
  set {
    name  = "appsec.configs.custom-appsec-config\\.yaml"
    value = <<-EOF
      name: crowdsecurity/custom-appsec-config
      default_remediation: ban
      outofband_rules:
        - crowdsecurity/crs
      inband_rules:
        - crowdsecurity/base-config
        - crowdsecurity/vpatch-*
        - crowdsecurity/generic-*
    EOF
  }
  set {
    name  = "appsec.env[0].name"
    value = "COLLECTIONS"
  }
  set {
    name  = "appsec.env[0].value"
    value = "crowdsecurity/appsec-crs crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-generic-rules"
  }
  set {
    name  = "appsec.env[1].name"
    value = "APPSEC_RULES"
  }
  set {
    name  = "appsec.env[1].value"
    value = "crowdsecurity/base-config"
  }

  set {
    name  = "lapi.persistentVolume.data.existingClaim"
    value = kubernetes_persistent_volume_claim.crowdsec["lapi-data"].metadata[0].name
  }
  set {
    name  = "lapi.persistentVolume.config.existingClaim"
    value = kubernetes_persistent_volume_claim.crowdsec["lapi-config"].metadata[0].name
  }
}
