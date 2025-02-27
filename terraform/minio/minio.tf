locals {
  minio_domain         = "minio.${var.server_base_domain}"
  minio_console_domain = "minio-console.${var.server_base_domain}"
}

resource "kubernetes_job" "minio_chown" {
  metadata {
    name      = "minio-chown"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          image = "alpine:3.21.0"
          name  = "minio-chown"

          command = ["sh", "-c", "chown -R 1000:1000 /export"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            mount_path = "/export"
            name       = "minio-data"
          }
        }

        volume {
          name = "minio-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.minio.metadata[0].name
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 0
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

resource "helm_release" "minio" {
  name = "minio"

  repository = "https://charts.min.io/"
  chart      = "minio"
  version    = "5.2.0"

  namespace = kubernetes_namespace.minio.metadata[0].name

  timeout = 300

  set {
    name  = "mode"
    value = "standalone"
  }

  set {
    name  = "replicas"
    value = "1"
  }
  set {
    name  = "drivesPerNode"
    value = "1"
  }

  set_sensitive {
    name  = "rootUser"
    value = random_password.minio_root_username.result
  }
  set_sensitive {
    name  = "rootPassword"
    value = random_password.minio_root_password.result
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.minio.metadata[0].name
  }
  set {
    name  = "persistence.size"
    value = kubernetes_persistent_volume_claim.minio.spec[0].resources[0].requests.storage
  }

  set {
    name  = "ingress.enabled"
    value = "false"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "resources.requests.memory"
    value = "1G"
  }
  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }
  set {
    name  = "resources.limits.memory"
    value = "2G"
  }

  set {
    name  = "environment.MINIO_DOMAIN"
    value = local.minio_domain
  }
  set {
    name  = "environment.MINIO_BROWSER_REDIRECT_URL"
    value = "https://${local.minio_console_domain}"
  }

  set {
    name  = "oidc.enabled"
    value = "true"
  }
  set {
    name  = "oidc.configUrl"
    value = "${data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url}/.well-known/openid-configuration"
  }
  set {
    name  = "oidc.clientId"
    value = keycloak_openid_client.minio.name
  }
  set_sensitive {
    name  = "oidc.clientSecret"
    value = random_password.keycloak_client_secret.result
  }
  set {
    name  = "oidc.claimName"
    value = keycloak_openid_user_client_role_protocol_mapper.minio_claim_mapper.claim_name # the values in this claim need to match up to policy names
  }
  set {
    name  = "oidc.redirectUri"
    value = "https://${local.minio_console_domain}/oauth_callback"
  }
  set {
    name  = "oidc.displayName"
    value = "Keycloak"
  }

  depends_on = [
    kubernetes_job.minio_chown
  ]
}

module "minio_ingress" {
  source = "../modules/ingress"

  name      = "minio"
  namespace = kubernetes_namespace.minio.metadata[0].name
  domain    = local.minio_domain

  target_port = 9000

  existing_service_name      = helm_release.minio.name
  existing_service_namespace = helm_release.minio.namespace
}

module "minio_console_ingress" {
  source = "../modules/ingress"

  name      = "minio-console"
  namespace = kubernetes_namespace.minio.metadata[0].name
  domain    = local.minio_console_domain

  target_port = 9001

  existing_service_name      = "${helm_release.minio.name}-console"
  existing_service_namespace = helm_release.minio.namespace
}
