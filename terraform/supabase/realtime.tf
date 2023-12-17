resource "kubernetes_config_map" "realtime_env" {
  metadata {
    name      = "realtime-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    PORT                   = "4000"
    DB_HOST                = kubernetes_service.db.metadata[0].name
    DB_PORT                = kubernetes_config_map.db_env.data.PGPORT
    DB_USER                = "supabase_admin"
    DB_NAME                = kubernetes_config_map.db_env.data.PGDATABASE
    DB_AFTER_CONNECT_QUERY = "'SET search_path TO _realtime'"
    DB_ENC_KEY             = "supabaserealtime"
    FLY_ALLOC_ID           = "fly123" # *****
    FLY_APP_NAME           = "realtime"
    ERL_AFLAGS             = "-proto_dist inet_tcp"
    ENABLE_TAILSCALE       = "false"
    DNS_NODES              = "''"
  }
}

resource "kubernetes_secret" "realtime_env" {
  metadata {
    name      = "realtime-env"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  data = {
    DB_PASSWORD     = random_password.db_password.result
    API_JWT_SECRET  = random_password.jwt_secret.result
    SECRET_KEY_BASE = random_password.secret_base_key.result
  }
}

resource "kubernetes_deployment" "realtime" {
  metadata {
    name      = "realtime"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "supabase"
        component = "realtime"
      }
    }

    template {
      metadata {
        labels = {
          app       = "supabase"
          component = "realtime"
        }
      }

      spec {
        container {
          image = "supabase/realtime:v2.25.35"
          name  = "realtime"

          command = ["sh -c \"/app/bin/migrate && /app/bin/realtime eval 'Realtime.Release.seeds(Realtime.Repo)' && /app/bin/server\""]

          # *****
          # healthcheck:
          # test:
          # [
          # "CMD",
          # "bash",
          # "-c",
          # "printf \\0 > /dev/tcp/localhost/4000"
          # ]
          # timeout: 5s
          # interval: 5s
          # retries: 3

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
              name = kubernetes_config_map.realtime_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.realtime_env.metadata[0].name
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

resource "kubernetes_service" "realtime" {
  metadata {
    name      = "realtime"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    selector = {
      app       = "supabase"
      component = "realtime"
    }

    port {
      port        = 80
      target_port = kubernetes_config_map.realtime_env.data.PORT
    }
  }
}
