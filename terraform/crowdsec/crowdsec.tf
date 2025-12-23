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
  version    = "0.21.1"

  namespace = kubernetes_namespace.crowdsec.metadata[0].name

  timeout = 300

  set = [
    {
      name  = "config.config\\.yaml\\.local"
      value = <<-EOF
        api:
          server:
            auto_registration: # Activate if not using TLS for authentication or when using Appsec
              enabled: true
              token: "$${REGISTRATION_TOKEN}" # /!\ Do not modify this variable (auto-generated and handled by the chart)
              allowed_ranges:
                - "10.0.0.0/8"
      EOF
    },
    {
      name  = "config.parsers.s00-raw.custom-cri-logs\\.yaml"
      # we have to set the filter to true to force it always to be used - some sort of mismatch between what k3s logging sets and what crowdsec expects
      # it should be safe, since all logs should be in this format, and we're only expecting to get logs from Traefik anyway
      # from: https://app.crowdsec.net/hub/author/crowdsecurity/log-parsers/cri-logs
      # check for updates occasionally
      value = <<-EOF
        filter: true
        onsuccess: next_stage
        name: crowdsecurity/cri-logs
        description: CRI logging format parser
        nodes:
          - grok:
              pattern: "^%%{TIMESTAMP_ISO8601:cri_timestamp} %%{WORD:stream} %%{WORD:logtag} %%{GREEDYDATA:message}"
              apply_on: Line.Raw
        statics:
          - parsed: "logsource"
            value: "cri"
          - target: evt.StrTime
            expression: evt.Parsed.cri_timestamp
          - parsed: program
            expression: evt.Line.Labels.program
          - meta: datasource_path
            expression: evt.Line.Src
          - meta: datasource_type
            expression: evt.Line.Module
      EOF
    },
    {
      name  = "lapi.env[0].name"
      value = "ENROLL_KEY"
    },
    {
      name  = "lapi.env[1].name"
      value = "ENROLL_INSTANCE_NAME"
    },
    {
      name  = "lapi.env[1].value"
      value = "k3s-homelab"
    },
    {
      name  = "lapi.env[2].name"
      value = "ENROLL_TAGS"
    },
    {
      name  = "lapi.env[2].value"
      value = local.crowdsec_enroll_tags
    },
    {
      name  = "lapi.env[3].name"
      value = "BOUNCER_KEY_traefik"
    },
    {
      name  = "lapi.env[3].value"
      value = random_password.traefik_api_key.result
    },
    {
      name  = "agent.acquisition[0].namespace"
      value = data.terraform_remote_state.traefik.outputs.traefik_namespace
    },
    {
      name  = "agent.acquisition[0].podName"
      value = "${data.terraform_remote_state.traefik.outputs.traefik_helm_release_name}-*"
    },
    {
      name  = "agent.acquisition[0].program"
      value = "traefik"
    },
    {
      name  = "agent.acquisition[0].poll_without_inotify"
      value = "true"
    },
    {
      name  = "agent.env[0].name"
      value = "COLLECTIONS"
    },
    {
      name  = "agent.env[0].value"
      value = "crowdsecurity/traefik"
    },
    {
      name  = "appsec.enabled"
      value = "true"
    },
    {
      name  = "appsec.acquisitions[0].source"
      value = "appsec"
    },
    {
      name  = "appsec.acquisitions[0].listen_addr"
      value = "0.0.0.0:7422"
    },
    {
      name  = "appsec.acquisitions[0].path"
      value = "/"
    },
    {
      name  = "appsec.acquisitions[0].appsec_config"
      value = "crowdsecurity/custom-appsec-config"
    },
    {
      name  = "appsec.acquisitions[0].labels.type"
      value = "appsec"
    },
    {
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
    },
    {
      name  = "appsec.env[0].name"
      value = "COLLECTIONS"
    },
    {
      name  = "appsec.env[0].value"
      value = "crowdsecurity/appsec-crs crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-generic-rules"
    },
    {
      name  = "appsec.env[1].name"
      value = "APPSEC_RULES"
    },
    {
      name  = "appsec.env[1].value"
      value = "crowdsecurity/base-config"
    },
    {
      name  = "lapi.persistentVolume.data.existingClaim"
      value = kubernetes_persistent_volume_claim.crowdsec["lapi-data"].metadata[0].name
    },
    {
      name  = "lapi.persistentVolume.config.existingClaim"
      value = kubernetes_persistent_volume_claim.crowdsec["lapi-config"].metadata[0].name
    },
  ]

  set_sensitive = [
    {
      name  = "secrets.username"
      value = random_password.crowdsec_agent_username.result
    },
    {
      name  = "secrets.password"
      value = random_password.crowdsec_agent_password.result
    },
    {
      name  = "lapi.env[0].value"
      value = var.crowdsec_enroll_key
    },
    {
      name  = "lapi.secrets.csLapiSecret"
      value = random_password.crowdsec_lapi_secret.result
    },
    {
      name  = "lapi.secrets.registrationToken"
      value = random_password.crowdsec_registration_token.result
    },
  ]
}
