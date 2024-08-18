resource "helm_release" "actions_runner_controller" {
  name = "scale-set-controller"

  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = local.arc_version

  namespace = kubernetes_namespace.github_org_runners.metadata[0].name

  timeout = 300

  set {
    name  = "flags.logLevel"
    value = "info"
  }
}
