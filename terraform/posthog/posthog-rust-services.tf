# ==================== Rust services ====================

resource "kubernetes_deployment" "capture" {
  metadata {
    name      = "capture"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "capture" }
    }
    template {
      metadata {
        labels = { app = "capture" }
      }
      spec {
        container {
          image = local.rust_images.capture
          name  = "capture"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.capture_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          port { container_port = 3000 }

          resources {
            requests = { cpu = "200m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_service" "capture" {
  metadata {
    name      = "capture"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "capture" }
    port {
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "replay_capture" {
  metadata {
    name      = "replay-capture"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "replay-capture" }
    }
    template {
      metadata {
        labels = { app = "replay-capture" }
      }
      spec {
        container {
          image = local.rust_images.capture
          name  = "replay-capture"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.replay_capture_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          port { container_port = 3000 }

          resources {
            requests = { cpu = "200m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_service" "replay_capture" {
  metadata {
    name      = "replay-capture"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "replay-capture" }
    port {
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "capture_ai" {
  metadata {
    name      = "capture-ai"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "capture-ai" }
    }
    template {
      metadata {
        labels = { app = "capture-ai" }
      }
      spec {
        container {
          image = local.rust_images.capture
          name  = "capture-ai"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.capture_ai_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.capture_ai_secrets.metadata[0].name }
          }

          port { container_port = 3000 }

          resources {
            requests = { cpu = "200m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_service" "capture_ai" {
  metadata {
    name      = "capture-ai"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "capture-ai" }
    port {
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "capture_logs" {
  metadata {
    name      = "capture-logs"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "capture-logs" }
    }
    template {
      metadata {
        labels = { app = "capture-logs" }
      }
      spec {
        container {
          image = local.rust_images.capture-logs
          name  = "capture-logs"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.capture_logs_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.capture_logs_secrets.metadata[0].name }
          }

          port { container_port = 4318 }

          resources {
            requests = { cpu = "200m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_service" "capture_logs" {
  metadata {
    name      = "capture-logs"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "capture-logs" }
    port {
      port        = 4318
      target_port = 4318
    }
  }
}

resource "kubernetes_deployment" "property_defs_rs" {
  metadata {
    name      = "property-defs-rs"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "property-defs-rs" }
    }
    template {
      metadata {
        labels = { app = "property-defs-rs" }
      }
      spec {
        container {
          image = local.rust_images.property-defs-rs
          name  = "property-defs-rs"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.property_defs_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_deployment" "feature_flags" {
  metadata {
    name      = "feature-flags"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "feature-flags" }
    }
    template {
      metadata {
        labels = { app = "feature-flags" }
      }
      spec {
        container {
          image = local.rust_images.feature-flags
          name  = "feature-flags"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.feature_flags_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.feature_flags_secrets.metadata[0].name }
          }

          port { container_port = 3001 }

          resources {
            requests = { cpu = "100m", memory = "256Mi" }
            limits   = { cpu = "250m", memory = "512Mi" }
          }

          volume_mount {
            name       = "geoip"
            mount_path = "/share"
          }
        }

        volume {
          name = "geoip"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.geoip.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate, kubernetes_job.geoip_download]
}

resource "kubernetes_service" "feature_flags" {
  metadata {
    name      = "feature-flags"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "feature-flags" }
    port {
      port        = 3001
      target_port = 3001
    }
  }
}

resource "kubernetes_deployment" "personhog_replica" {
  metadata {
    name      = "personhog-replica"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "personhog-replica" }
    }
    template {
      metadata {
        labels = { app = "personhog-replica" }
      }
      spec {
        container {
          image = local.rust_images.personhog-replica
          name  = "personhog-replica"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.personhog_replica_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          port { container_port = 50051 }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_service" "personhog_replica" {
  metadata {
    name      = "personhog-replica"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "personhog-replica" }
    port {
      port        = 50051
      target_port = 50051
    }
  }
}

resource "kubernetes_deployment" "personhog_router" {
  metadata {
    name      = "personhog-router"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "personhog-router" }
    }
    template {
      metadata {
        labels = { app = "personhog-router" }
      }
      spec {
        container {
          image = local.rust_images.personhog-router
          name  = "personhog-router"

          env_from {
            config_map_ref { name = kubernetes_config_map.personhog_router_config.metadata[0].name }
          }

          port { container_port = 50052 }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_deployment.personhog_replica]
}

resource "kubernetes_service" "personhog_router" {
  metadata {
    name      = "personhog-router"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "personhog-router" }
    port {
      port        = 50052
      target_port = 50052
    }
  }
}

resource "kubernetes_deployment" "hypercache_server" {
  metadata {
    name      = "hypercache-server"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "hypercache-server" }
    }
    template {
      metadata {
        labels = { app = "hypercache-server" }
      }
      spec {
        container {
          image = local.rust_images.hypercache-server
          name  = "hypercache-server"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.hypercache_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }

          port { container_port = 3002 }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }
        }
      }
    }
  }
  depends_on = [helm_release.valkey]
}

resource "kubernetes_service" "hypercache_server" {
  metadata {
    name      = "hypercache-server"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "hypercache-server" }
    port {
      port        = 3002
      target_port = 3002
    }
  }
}

resource "kubernetes_deployment" "cyclotron_janitor" {
  metadata {
    name      = "cyclotron-janitor"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "cyclotron-janitor" }
    }
    template {
      metadata {
        labels = { app = "cyclotron-janitor" }
      }
      spec {
        container {
          image = local.rust_images.cyclotron-janitor
          name  = "cyclotron-janitor"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.cyclotron_janitor_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.cyclotron_janitor_secrets.metadata[0].name }
          }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate]
}

resource "kubernetes_deployment" "livestream" {
  metadata {
    name      = "livestream"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "livestream" }
    }
    template {
      metadata {
        labels = { app = "livestream" }
      }
      spec {
        container {
          image = local.rust_images.livestream
          name  = "livestream"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.livestream_secrets.metadata[0].name }
          }

          port { container_port = 8080 }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }

          volume_mount {
            name       = "geoip"
            mount_path = "/share"
          }

          volume_mount {
            name       = "livestream-config"
            mount_path = "/configs"
          }
        }

        volume {
          name = "geoip"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.geoip.metadata[0].name
          }
        }

        volume {
          name = "livestream-config"
          config_map {
            name = kubernetes_config_map.livestream_config.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [kubernetes_service.kafka, kubernetes_job.geoip_download]
}

resource "kubernetes_service" "livestream" {
  metadata {
    name      = "livestream"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "livestream" }
    port {
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_deployment" "cymbal" {
  metadata {
    name      = "cymbal"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "cymbal" }
    }
    template {
      metadata {
        labels = { app = "cymbal" }
      }
      spec {
        container {
          image = local.rust_images.cymbal
          name  = "cymbal"

          env_from {
            config_map_ref { name = kubernetes_config_map.posthog_env.metadata[0].name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.cymbal_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.posthog_secrets.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.cymbal_secrets.metadata[0].name }
          }

          port { container_port = 3302 }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }

          volume_mount {
            name       = "geoip"
            mount_path = "/share"
          }
        }

        volume {
          name = "geoip"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.geoip.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.posthog_migrate, kubernetes_job.geoip_download]
}

resource "kubernetes_service" "cymbal" {
  metadata {
    name      = "cymbal"
    namespace = kubernetes_namespace.posthog.metadata[0].name
  }
  spec {
    selector = { app = "cymbal" }
    port {
      port        = 3302
      target_port = 3302
    }
  }
}
