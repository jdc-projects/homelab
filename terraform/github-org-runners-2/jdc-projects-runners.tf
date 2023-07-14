resource "kubernetes_manifest" "github_org_runners_deployment" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"

    metadata = {
      name      = "jdc-projects-runners-deployment"
      namespace = data.terraform_remote_state.github_org_runners_1.outputs.github_org_runners_namespace_name
    }

    spec = {
      template = {
        spec = {
          image = "summerwind/actions-runner:v2.305.0-ubuntu-22.04"

          organization = "jdc-projects"
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
      name      = "jdc-projects-runners-autoscaler"
      namespace = data.terraform_remote_state.github_org_runners_1.outputs.github_org_runners_namespace_name
    }

    spec = {
      minReplicas = "5"
      maxReplicas = "20"

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
