resource "kubernetes_secret" "cloudflare_creds" {
  metadata {
    name      = "cloudflare-creds"
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }

  data = {
    api-token = var.cloudflare_acme_token
  }
}

resource "kubernetes_manifest" "cert_manager_issuer_le_staging" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"

    metadata = {
      name      = "le-staging"
      namespace = kubernetes_namespace.traefik.metadata[0].name
    }

    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = "jack.chapman@sky.com" # should parameterise this *****

        privateKeySecretRef = {
          name = "le-staging-key"
        }

        solvers = [{
          dns01 = {
            cloudflare = {
              apiTokenSecretRef = {
                name = kubernetes_secret.cloudflare_creds.metadata[0].name
                key  = "api-token"
              }
            }
          }
        }]
      }
    }
  }
}

resource "kubernetes_manifest" "cert_manager_issuer_le_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"

    metadata = {
      name      = "le-prod"
      namespace = kubernetes_namespace.traefik.metadata[0].name
    }

    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "jack.chapman@sky.com" # should parameterise this *****

        privateKeySecretRef = {
          name = "le-prod-key"
        }

        solvers = [{
          dns01 = {
            cloudflare = {
              apiTokenSecretRef = {
                name = kubernetes_secret.cloudflare_creds.metadata[0].name
                key  = "api-token"
              }
            }
          }
        }]
      }
    }
  }
}
