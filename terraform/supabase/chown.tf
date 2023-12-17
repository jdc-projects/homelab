resource "kubernetes_job" "chown" {
  for_each = tomap({
    storage = tomap({
      chown_uid = "1001"
      chown_gid = "1001"
    })
    functions = tomap({
      chown_uid = "1001"
      chown_gid = "1001"
    })
    db = tomap({
      chown_uid = "1000"
      chown_gid = "1000"
    })
  })

  metadata {
    name      = "supabase-${each.key}-chown"
    namespace = kubernetes_namespace.supabase.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          image = "alpine:3.18.4"
          name  = "supabase-${each.key}-chown"

          command = ["sh", "-c", "chown -R ${each.value.chown_uid}:${each.value.chown_gid} /chown && chmod -R 0700 /chown"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            mount_path = "/chown"
            name       = "chown-supabase-${each.key}-data"
          }
        }

        volume {
          name = "chown-supabase-${each.key}-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.supabase[each.key].metadata[0].name
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
