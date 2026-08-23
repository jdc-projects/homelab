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
  version    = "0.24.0"

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
      name = "config.parsers.s00-raw.custom-cri-logs\\.yaml"
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
      # base-config sets coraza body processors. The nextcloud CRS exclusion
      # plugin suppresses the well-known WebDAV/file-upload CRS false positives
      # on ownCloud/Nextcloud-style apps (OCIS shares the /remote.php/dav/*
      # surface). It is path-scoped, so only OCIS is relaxed.
      name  = "appsec.env[1].value"
      value = "crowdsecurity/base-config crowdsecurity/crs-exclusion-plugin-nextcloud"
    },
    {
      name  = "lapi.metrics.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "agent.metrics.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "lapi.resources.limits.cpu"
      value = "1000m"
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

  # The AppSec config must be passed via `values` (a rendered values file),
  # never the `set` list: helm parses `set` values with --set/strvals
  # semantics, which splits values on commas. YAML containing commas gets
  # silently truncated at the first comma (this previously amputated the idp
  # token-endpoint entry mid-comment) or fails to apply outright
  # ("key ... has no value (cannot end with ,)").
  values = [<<-YAML
    appsec:
      configs:
        custom-appsec-config.yaml: |
          name: crowdsecurity/custom-appsec-config
          default_remediation: ban
          inband_rules:
            - crowdsecurity/base-config
            - crowdsecurity/vpatch-*
            - crowdsecurity/generic-*
          outofband_rules:
            - crowdsecurity/crs
          on_load:
            - apply:
                # Truncate (don't block) oversized request bodies so large uploads
                # never get auto-banned by the body-size guard.
                - SetBodySizeExceededAction("partial")
                - SetMaxBodySize(52428800)
          pre_eval:
            # Each filter MUST be scoped to the app hostname via req.Host so it
            # does not leak to other apps sharing the same AppSec engine. Add
            # new entries when an app has request bodies that trip CRS rules.
            - filter: req.Host == "ocis.${var.server_base_domain}" && req.URL.Path startsWith "/dav/"
              apply:
                - DisableBodyInspection()
            - filter: req.Host == "outline.${var.server_base_domain}" && ((req.URL.Path startsWith "/api/documents") || (req.URL.Path startsWith "/api/attachments") || (req.URL.Path startsWith "/api/hooks"))
              apply:
                - DisableBodyInspection()
            - filter: req.Host == "assets-notes.${var.server_base_domain}"
              apply:
                - DisableBodyInspection()
            - filter: req.Host == "grafana.${var.server_base_domain}" && req.URL.Path startsWith "/api/ds/query"
              apply:
                - DisableBodyInspection()
          on_match:
            # Scoped CRS exceptions for hosts/paths where legitimate traffic trips CRS
            # rules. Same scoping rule as pre_eval: every filter must pin req.Host.
            # cap: host-wide — captcha service whose sensitive endpoints already
            # require a secret key; dashboard assets and base64 challenge/redeem
            # tokens false-positive CRS body inspection (933120 et al).
            - filter: req.Host == "cap.${var.server_base_domain}"
              apply:
                - CancelAlert()
                - CancelEvent()
                - SetRemediation("allow")
            # idp: OIDC token endpoint only — client-credentials/token POST bodies
            # (secrets, opaque tokens) trip CRS; keep CRS active on the rest of idp.
            - filter: req.Host == "idp.${var.server_base_domain}" && req.URL.Path endsWith "/protocol/openid-connect/token"
              apply:
                - CancelAlert()
                - CancelEvent()
                - SetRemediation("allow")
            # idp: Keycloak Admin REST API — already gated by a master-realm bearer
            # token; its JSON bodies (user credentials, client secrets) false-positive
            # the out-of-band CRS rules (crowdsec-appsec-outofband), banning the home
            # IP and cascading into other services' deploys. Path-scoped: the rest
            # of idp keeps full CRS.
            - filter: req.Host == "idp.${var.server_base_domain}" && req.URL.Path startsWith "/admin/"
              apply:
                - CancelAlert()
                - CancelEvent()
                - SetRemediation("allow")
  YAML
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
