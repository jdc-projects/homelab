resource "kubernetes_job" "runners_cache_chown" {
  for_each = tomap({
    tool-cache = tomap({
      chown_uid = "1001"
      chown_gid = "121"
    })
  })

  metadata {
    name      = "runners-cache-chown-${each.key}"
    namespace = data.terraform_remote_state.github_org_runners_1.outputs.github_org_runners_namespace_name
  }

  spec {
    template {
      metadata {}

      spec {
        container {
          image = "alpine:3.18.4"
          name  = "runners-cache-chown-${each.key}"

          command = ["sh", "-c", "chown -R ${each.value.chown_uid}:${each.value.chown_gid} /chown"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            mount_path = "/chown"
            name       = each.key
          }
        }

        volume {
          name = each.key

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.runners[each.key].metadata[0].name
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

resource "kubernetes_manifest" "github_org_runners_set" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerSet"

    metadata = {
      name      = "github-org-runners-set"
      namespace = data.terraform_remote_state.github_org_runners_1.outputs.github_org_runners_namespace_name
    }

    spec = {
      organization = var.github_org_name

      selector = {
        matchLabels = {
          app = "github-org-runners"
        }
      }

      serviceName = "github-org-runners"

      template = {
        metadata = {
          labels = {
            app = "github-org-runners"
          }
        }

        spec = {
          containers = [
            {
              name = "runner"

              # source: https://github.com/actions/actions-runner-controller/issues/2726#issuecomment-1734202361
              volumeMounts = [{
                mountPath = "/opt/hostedtoolcache"
                name      = "tool-cache"
              }]

              resources = {
                requests = {
                  cpu    = "200m"
                  memory = "512Mi"
                }

                limits = {
                  cpu    = "500m"
                  memory = "1024Mi"
                }
              }
            },
            {
              name = "docker"

              resources = {
                requests = {
                  cpu    = "200m"
                  memory = "512Mi"
                }

                limits = {
                  cpu    = "500m"
                  memory = "1024Mi"
                }
              }
            }
          ]

          volumes = [{
            name = "tool-cache"
            persistentVolumeClaim = {
              claimName = kubernetes_persistent_volume_claim.runners["tool-cache"].metadata[0].name
            }
          }]
        }
      }
    }
  }

  depends_on = [kubernetes_job.runners_cache_chown]
}

resource "kubernetes_manifest" "github_org_runners_autoscaler" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"

    metadata = {
      name      = "github-org-runners-autoscaler"
      namespace = data.terraform_remote_state.github_org_runners_1.outputs.github_org_runners_namespace_name
    }

    spec = {
      minReplicas = "10"
      maxReplicas = "20"

      scaleTargetRef = {
        kind = "RunnerSet"
        name = kubernetes_manifest.github_org_runners_set.manifest.metadata.name
      }

      scaleUpTriggers = [{
        githubEvent = {
          workflowJob = {}
        }

        duration = "30m"
      }]
    }
  }

  lifecycle {
    replace_triggered_by = [kubernetes_persistent_volume_claim.runners]
  }
}
