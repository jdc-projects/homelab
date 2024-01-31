resource "kubernetes_namespace" "cloudflare_ddns" {
  metadata {
    name = "cloudflare-ddns"
  }
}

resource "kubernetes_secret" "cloudflare_ddns_env" {
  metadata {
    name      = "cloudflare-ddns-env"
    namespace = kubernetes_namespace.cloudflare_ddns.metadata[0].name
  }

  data = {
    API_KEY = var.cloudflare_ddns_token
  }
}

resource "kubernetes_config_map" "cloudflare_ddns_env" {
  metadata {
    name      = "cloudflare-ddns-env"
    namespace = kubernetes_namespace.cloudflare_ddns.metadata[0].name
  }

  data = {
    ZONE = var.server_base_domain
    SUBDOMAIN = "*"
  }
}

resource "kubernetes_deployment" "cloudflare_ddns_deployment" {
  metadata {
    name      = "cloudflare-ddns"
    namespace = kubernetes_namespace.cloudflare_ddns.metadata[0].name
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
          image = "oznu/cloudflare-ddns:latest"
          name  = "cloudflare-ddns"

          env_from {
            secret_ref {
              name = kubernetes_secret.cloudflare_ddns_env.metadata[0].name
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.cloudflare_ddns_env.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}
