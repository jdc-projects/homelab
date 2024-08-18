locals {
  arc_version = "0.9.3"
}

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

resource "helm_release" "runner_scale_set" {
  name = "github-org-runners-controller"

  repository = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set"
  chart      = "runner-scale-set"
  version    = local.arc_version

  namespace = kubernetes_namespace.github_org_runners.metadata[0].name

  timeout = 300

  set {
    name  = "githubConfigUrl"
    value = "https://github.com/${var.github_org_name}"
  }

  set {
    name  = "githubConfigSecret.github_app_id"
    value = var.github_org_runners_app_id
  }
  set {
    name  = "githubConfigSecret.github_app_installation_id"
    value = var.github_org_runners_app_installation_id
  }
  set_sensitive {
    name  = "githubConfigSecret.github_app_private_key"
    value = var.github_org_runners_app_private_key
  }

  set {
    name  = "maxRunners"
    value = "20"
  }
  set {
    name  = "minRunners"
    value = "10"
  }

  set {
    name  = "containerMode.type"
    value = "kubernetes"
  }
  set {
    name  = "containerMode.kubernetesModeWorkVolumeClaim.accessModes"
    value = "[ \"ReadWriteOnce\" ]"
  }
  set {
    name  = "containerMode.kubernetesModeWorkVolumeClaim.storageClassName"
    value = "openebs-zfs-localpv-general-no-backup"
  }
  set {
    name  = "containerMode.kubernetesModeWorkVolumeClaim.resources.requests.storage"
    value = "1Gi"
  }

  set {
    name  = "template.spec.containers[0].name"
    value = "runner"
  }
  set {
    name  = "template.spec.containers[0].image"
    value = "ghcr.io/actions/actions-runner:2.319.1"
  }
  set {
    name  = "template.spec.containers[0].command:"
    value = "[\"/home/runner/run.sh\"]"
  }
  set {
    name  = "template.spec.containers[0].env[0].name"
    value = "ACTIONS_RUNNER_CONTAINER_HOOKS"
  }
  set {
    name = "template.spec.containers[0].env[0].value"
    value = "/home/runner/k8s/index.js"
  }
  set {
    name  = "template.spec.containers[0].env[1].name"
    value = "ACTIONS_RUNNER_POD_NAME"
  }
  set {
    name = "template.spec.containers[0].env[1].valueFrom.fieldRef.fieldPath"
    value = "metadata.name"
  }
  set {
    name  = "template.spec.containers[0].env[2].name"
    value = "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER"
  }
  set {
    name  = "template.spec.containers[0].env[2].value"
    value = "true"
  }
  set {
    name  = "template.spec.containers[0].env[3].name"
    value = "DISABLE_RUNNER_UPDATE"
  }
  set {
    name  = "template.spec.containers[0].env[3].value"
    value = "true"
  }
  set {
    name  = "template.spec.containers[0].volumeMounts[0].name"
    value = "work"
  }
  set {
    name  = "template.spec.containers[0].volumeMounts[0].mountPath"
    value = "/home/runner/_work"
  }
  # ***** hosted-tool cache *****
  set {
    name  = "template.spec.volumes[0].name"
    value = "work"
  }
  set {
    name  = "template.spec.volumes[0].ephemeral.volumeClaimTemplate.spec.accessModes"
    value = "[ \"ReadWriteOnce\" ]"
  }
  set {
    name  = "template.spec.volumes[0].ephemeral.volumeClaimTemplate.spec.storageClassName"
    value = "openebs-zfs-localpv-general-no-backup"
  }
  set {
    name  = "template.spec.volumes[0].ephemeral.volumeClaimTemplate.spec.resources.requests.storage"
    value = "1Gi"
  }
  # ***** hosted-tool cache *****
}
