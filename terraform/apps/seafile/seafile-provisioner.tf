resource "kubernetes_secret" "seafile_provisioner_env" {
  metadata {
    name      = "seafile-provisioner-env"
    namespace = kubernetes_namespace.seafile.metadata[0].name
  }

  data = {
    DB_HOST                    = helm_release.mariadb.name
    DB_ROOT_PASSWD             = random_password.mariadb_root_password.result
    TIME_ZONE                  = "UTC"
    SEAFILE_ADMIN_EMAIL        = "admin@${var.server_base_domain}"
    SEAFILE_ADMIN_PASSWORD     = random_password.seafile_admin_password.result
    SEAFILE_SERVER_LETSENCRYPT = "false"
    SEAFILE_SERVER_HOSTNAME    = "seafile.${var.server_base_domain}"
  }
}

resource "kubernetes_job" "seafile-provisioner" {
  metadata {
    name      = "seafile-provisioner"
    namespace = kubernetes_namespace.seafile.metadata[0].name
  }

  spec {
    template {
      metadata {
      }

      spec {
        container {
          image   = "seafileltd/seafile-mc:${null_resource.seafile_version.triggers.version}"
          name    = "seafile-provisioner"
          command = ["/opt/seafile/seafile-server-${null_resource.seafile_version.triggers.version}/setup-seafile-mysql.sh", "auto", "-n", "seafile", "-i", "seafile.${var.server_base_domain}", "-o", "${helm_release.mariadb.name}", "-u", "seafile", "-w", "${random_password.mariadb_seafile_password.result}", "-q", "%", "-r", "${random_password.mariadb_root_password.result}"]

          env_from {
            secret_ref {
              name = kubernetes_secret.seafile_provisioner_env.metadata[0].name
            }
          }

          # volume_mount {
          #   mount_path = "/shared"
          #   name       = "seafile-data"
          # }
        }

        # volume {
        #   name = "seafile-data"

        #   host_path {
        #     path = truenas_dataset.seafile.mount_point
        #   }
        # }

        active_deadline_seconds = "90"
        restart_policy          = "Never"
      }
    }

    backoff_limit = 0
  }

  wait_for_completion = true

  timeouts {
    create = "2m"
    update = "2m"
  }
}
