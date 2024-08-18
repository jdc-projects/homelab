resource "helm_release" "actions_runner_controller" {
  name = "github-org-runners-controller"

  repository = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller"
  chart      = "actions-runner-controller"
  version    = local.arc_version

  namespace = kubernetes_namespace.github_org_runners.metadata[0].name

  timeout = 300

  set {
    name  = "flags.logLevel"
    value = "info"
  }
}
