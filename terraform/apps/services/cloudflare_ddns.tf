resource "kubernetes_namespace" "cloudflare_ddns_namespace" {
  metadata {
    name = "cloudflare_ddns"
  }
}

# secret for api key
resource "kubernetes_secret" "cloudflare_ddns_api__key_secret" {
  metadata {
    name      = "cloudflare_ddns_api_key"
    namespace = kubernetes_namespace.cloudflare_ddns_namespace.metadata[0].name
  }

  data {
    API_KEY = var.cloudflare_ddns_api_key
  }
}

resource "kubernetes_deployment" "cloudflare_ddns" {
  metadata {
    name      = "cloudflare_ddns"
    namespace = kubernetes_namespace.cloudflare_ddns_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    template {
      spec {
        container {
          image = "oznu/cloudflare-ddns"

          env_from {
            secret_ref {
              name = kubernetes_secret.cloudflare_ddns_api__key_secret.metadata[0].name
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
