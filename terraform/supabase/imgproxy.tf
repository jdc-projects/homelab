resource "kubernetes_config_map" "imgproxy_env" {
  metadata {
    name      = "imgproxy-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    IMGPROXY_BIND                  = ":5001"
    IMGPROXY_LOCAL_FILESYSTEM_ROOT = "/"
    IMGPROXY_USE_ETAG              = "true"
    IMGPROXY_ENABLE_WEBP_DETECTION = "true"
  }
}

resource "kubernetes_secret" "imgproxy_env" {
  metadata {
    name      = "imgproxy-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
  }
}

resource "kubernetes_deployment" "imgproxy" {
  metadata {
    name      = "imgproxy"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "imgproxy"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "imgproxy"
        }
      }

      spec {
        container {
          image = "darthsim/imgproxy:v3.8.0"
          name  = "imgproxy"

          # *****
          # healthcheck:
          #   test: [ "CMD", "imgproxy", "health" ]
          #   timeout: 5s
          #   interval: 5s
          #   retries: 3

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

          env_from {
            config_map_ref {
              name = kubernetes_config_map.imgproxy_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.imgproxy_env.metadata[0].name
            }
          }

          volume_mount {
            mount_path = kubernetes_config_map.storage_env.data.FILE_STORAGE_BACKEND_PATH
            name       = "storage-data"
          }
        }

        volume {
          name = "storage-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.supabase["storage"].metadata[0].name
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }

  depends_on = [
    kubernetes_job.chown["storage"],
  ]
}

resource "kubernetes_service" "imgproxy" {
  metadata {
    name      = "imgproxy"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "imgproxy"
    }

    port {
      port        = 80
      target_port = 5001
    }
  }
}
