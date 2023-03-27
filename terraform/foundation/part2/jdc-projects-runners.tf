resource "kubernetes_manifest" "jdc_projects_runners_deployment" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"

    metadata = {
      name      = "jdc-projects-runners-deployment"
      namespace = data.terraform_remote_state.foundation_part1.outputs.jdc_projects_runners_namespace_name
    }

    spec = {
      template = {
        spec = {
          organization = "jdc-projects"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "jdc_projects_runners_autoscaler" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"

    metadata = {
      name      = "jdc-projects-runners-autoscaler"
      namespace = data.terraform_remote_state.foundation_part1.outputs.jdc_projects_runners_namespace_name
    }

    spec = {
      minReplicas = "5"
      maxReplicas = "20"

      scaleTargetRef = {
        kind = "RunnerDeployment"
        name = kubernetes_manifest.jdc_projects_runners_deployment.manifest.metadata.name
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
