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
  version    = "0.11.0"

  namespace = kubernetes_namespace.crowdsec.metadata[0].name

  timeout = 300

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
    name  = "lapi.persistentVolume.data.existingClaim"
    value = kubernetes_persistent_volume_claim.crowdsec_lapi_data.metadata[0].name
  }
  # force the config definition here to be the one used
  set {
    name  = "lapi.persistentVolume.config.enabled"
    value = "false"
  }
  set {
    name  = "agent.persistentVolume.config.enabled"
    value = "false"
  }
}
