resource "kubernetes_secret" "kubeconfig" {
  metadata {
    name      = "kubeconfig"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  data = {
    config = file("${path.module}/../cluster.yml")
  }
}

resource "kubernetes_config_map" "scripts" {
  metadata {
    name      = "scripts"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  data = {
    "docker-entrypoint.sh" = <<-EOF
      #! /bin/sh

      # add suid for crontab
      apk add --update busybox-suid

      # switch to prowler user
      su prowler -c "/home/prowler/scripts/setup.sh"

      # start cron
      crond -l 2 -f
    EOF
    "setup.sh"             = <<-EOF
      # run initial scan and start dashboard
      /home/prowler/scripts/scan.sh

      # setup cron job for scan
      crontab -l > ./crontab
      echo "0 23 * * * /home/prowler/scripts/scan.sh" >> ./crontab
      crontab ./crontab
      rm ./crontab
    EOF
    "scan.sh"              = <<-EOF
      #! /bin/sh
      prowler kubernetes --compliance ${join(" ", var.prowler_compliance_standards)} || true
      kill $(pgrep -f "bin/prowler dashboard") || true
      prowler dashboard &
    EOF
  }
}

resource "kubernetes_config_map" "prowler_env" {
  metadata {
    name      = "prowler-env"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  data = {
    HOST = "0.0.0.0"
    PORT = 8080
  }
}

resource "kubernetes_job" "prowler_chown" {
  metadata {
    name      = "prowler-chown"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          image = "alpine:3.22.2"
          name  = "prowler-chown"

          command = ["sh", "-c", "chown -R 1000:1000 /export"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            mount_path = "/export"
            name       = "prowler-output"
          }
        }

        volume {
          name = "prowler-output"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.prowler_output.metadata[0].name
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

resource "kubernetes_deployment" "prowler" {
  metadata {
    name      = "prowler"
    namespace = kubernetes_namespace.prowler.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prowler"
      }
    }

    template {
      metadata {
        labels = {
          app = "prowler"
        }
      }

      spec {
        container {
          image = "public.ecr.aws/prowler-cloud/prowler:5.14.0"
          name  = "prowler"

          command = [
            "/bin/sh", "-c", "/home/prowler/scripts/docker-entrypoint.sh"
          ]

          security_context {
            run_as_user = 0
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.prowler_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "kubeconfig"
            mount_path = "/home/prowler/.kube/"
          }

          volume_mount {
            name       = "scripts"
            mount_path = "/home/prowler/scripts/"
          }

          volume_mount {
            name       = "prowler-output"
            mount_path = "/home/prowler/output"
          }

          resources {
            requests = {
              cpu    = "1"
              memory = "2Gi"
            }

            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
          }
        }

        volume {
          name = "kubeconfig"

          secret {
            secret_name = kubernetes_secret.kubeconfig.metadata[0].name
          }
        }

        volume {
          name = "scripts"

          config_map {
            name         = kubernetes_config_map.scripts.metadata[0].name
            default_mode = "0777"
          }
        }

        volume {
          name = "prowler-output"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.prowler_output.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_secret.kubeconfig,
      kubernetes_config_map.scripts,
      kubernetes_config_map.prowler_env,
    ]
  }

  depends_on = [
    kubernetes_job.prowler_chown,
  ]
}

module "prowler_ingress" {
  source = "../modules/ingress"

  name      = "prowler"
  namespace = kubernetes_namespace.prowler.metadata[0].name
  domain    = "prowler.${var.server_base_domain}"

  target_port = kubernetes_config_map.prowler_env.data.PORT

  do_enable_keycloak_auth     = true
  is_keycloak_auth_admin_mode = true

  selector = {
    app = "prowler"
  }
}
