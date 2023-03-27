resource "kubernetes_namespace" "cloudflare_ddns_namespace" {
  metadata {
    name = "cloudflare-ddns"
  }
}

# secret for api key
resource "kubernetes_secret" "cloudflare_ddns_token_secret" {
  metadata {
    name      = "cloudflare-ddns-token"
    namespace = kubernetes_namespace.cloudflare_ddns_namespace.metadata[0].name
  }

  data = {
    API_KEY = var.cloudflare_ddns_token
  }
}

resource "kubernetes_deployment" "cloudflare_ddns" {
  metadata {
    name      = "cloudflare-ddns"
    namespace = kubernetes_namespace.cloudflare_ddns_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cloudflare-ddns"
      }
    }

    template {
      metadata {
        labels = {
          app = "cloudflare-ddns"
        }
      }

      spec {
        container {
          image = "oznu/cloudflare-ddns"
          name  = "cloudflare-ddns"

          env_from {
            secret_ref {
              name = kubernetes_secret.cloudflare_ddns_token_secret.metadata[0].name
            }
          }

          env {
            name  = "ZONE"
            value = var.server_base_domain
          }
        }
      }
    }
  }
}
