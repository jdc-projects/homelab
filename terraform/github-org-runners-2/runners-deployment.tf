resource "kubernetes_manifest" "github_org_runners_deployment" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"

    metadata = {
      name      = "github-org-runners-deployment"
      namespace = data.terraform_remote_state.github_org_runners_1.outputs.github_org_runners_namespace_name
    }

    spec = {
      template = {
        spec = {
          image = "summerwind/actions-runner:v2.306.0-ubuntu-22.04"

          organization = var.github_org_name
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
        kind = "RunnerDeployment"
        name = kubernetes_manifest.github_org_runners_deployment.manifest.metadata.name
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
