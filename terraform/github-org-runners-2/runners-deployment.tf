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
          containers = [{
            name = "runner"
            volumeMounts = [{
              mountPath = "/opt/hostedtoolcache"
              name = "tool-cache"
            }]
          }]

          volumes = [{
            name = "tool-cache"
            persistentVolumeClaim = {
              claimName = kubernetes_persistent_volume_claim.runners_cache.metadata[0].name
            }
          }]
        }
      }
    }
  }
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
      maxReplicas = "30"

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
}
