resource "kubernetes_config_map" "storage_env" {
  metadata {
    name      = "storage-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    POSTGREST_URL               = "http://rest"
    FILE_SIZE_LIMIT             = "52428800"
    STORAGE_BACKEND             = "file"
    FILE_STORAGE_BACKEND_PATH   = "/var/lib/storage"
    TENANT_ID                   = "stub"
    REGION                      = "stub"
    GLOBAL_S3_BUCKET            = "stub"
    ENABLE_IMAGE_TRANSFORMATION = "true"
    IMGPROXY_URL                = "imgproxy"
  }
}

resource "kubernetes_secret" "storage_env" {
  metadata {
    name      = "storage-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    ANON_KEY         = jwt_hashed_token.anon_key.token
    SERVICE_KEY      = jwt_hashed_token.service_key.token
    PGRST_JWT_SECRET = random_password.jwt_secret.result
    DATABASE_URL     = "postgres://supabase_storage_admin:${random_password.db_password.result}@${kubernetes_service.db.metadata[0].name}:${kubernetes_service.db.spec[0].port[0].port}/${kubernetes_config_map.db_env.data.PGDATABASE}"
  }
}

resource "kubernetes_deployment" "storage" {
  metadata {
    name      = "storage"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "storage"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "storage"
        }
      }

      spec {
        container {
          image = "supabase/storage-api:v0.43.11"
          name  = "storage"

          liveness_probe {
            http_get {
              path = "/status"
              port = 5000
            }

            initial_delay_seconds = 5
            period_seconds        = 5
            failure_threshold     = 3
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

          env_from {
            config_map_ref {
              name = kubernetes_config_map.storage_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.storage_env.metadata[0].name
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
    kubernetes_deployment.db,
    kubernetes_deployment.rest,
    kubernetes_deployment.imgproxy
  ]
}

resource "kubernetes_service" "storage" {
  metadata {
    name      = "storage"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "storage"
    }

    port {
      port        = 80
      target_port = kubernetes_deployment.storage.spec[0].template[0].spec[0].container[0].liveness_probe[0].http_get[0].port
    }
  }
}
