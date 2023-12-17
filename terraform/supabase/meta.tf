resource "kubernetes_config_map" "meta_env" {
  metadata {
    name      = "meta-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    PG_META_PORT    = "8080"
    PG_META_DB_HOST = kubernetes_service.db.metadata[0].name
    PG_META_DB_PORT = kubernetes_config_map.db_env.data.PGPORT
    PG_META_DB_NAME = kubernetes_config_map.db_env.data.PGDATABASE
    PG_META_DB_USER = "supabase_admin"
  }
}

resource "kubernetes_secret" "meta_env" {
  metadata {
    name      = "meta-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    PG_META_DB_PASSWORD = random_password.db_password.result
  }
}

resource "kubernetes_deployment" "meta" {
  metadata {
    name      = "meta"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "meta"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "meta"
        }
      }

      spec {
        container {
          image = "supabase/postgres-meta:v0.68.0"
          name  = "meta"

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
              name = kubernetes_config_map.meta_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.meta_env.metadata[0].name
            }
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
    kubernetes_deployment.db,
    kubernetes_deployment.analytics
  ]
}

resource "kubernetes_service" "meta" {
  metadata {
    name      = "meta"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "meta"
    }

    port {
      port        = 80
      target_port = kubernetes_config_map.meta_env.data.PG_META_PORT
    }
  }
}
