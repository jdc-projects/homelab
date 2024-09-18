locals {
  runner_uid = "1001"
  runner_gid = "1001"
}

resource "helm_release" "runner_scale_set" {
  name = "runner-scale-set"

  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
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
    name  = "runnerScaleSetName"
    value = "self-hosted"
  }

  set {
    name  = "containerMode.type"
    value = "kubernetes"
  }
  set {
    name  = "containerMode.kubernetesModeWorkVolumeClaim.accessModes[0]"
    value = "ReadWriteOnce"
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
    name  = "template.spec.initContainers[0].name"
    value = "chown-work"
  }
  set {
    name  = "template.spec.initContainers[0].image"
    value = "alpine:3.20.0"
  }
  set_list {
    name = "template.spec.initContainers[0].command"
    value = [
      "sh", "-c",
      "chown -R ${local.runner_uid}:${local.runner_gid} /chown",
    ]
  }
  set {
    name  = "template.spec.initContainers[0].securityContext.runAsUser"
    value = "0"
  }
  set {
    name  = "template.spec.initContainers[0].volumeMounts[0].name"
    value = "work"
  }
  set {
    name  = "template.spec.initContainers[0].volumeMounts[0].mountPath"
    value = "/chown"
  }
  set {
    name  = "template.spec.containers[0].name"
    value = "runner"
  }
  set {
    name  = "template.spec.containers[0].image"
    value = "ghcr.io/actions/actions-runner:${local.runner_version}"
  }
  set_list {
    name = "template.spec.containers[0].command"
    value = [
      "/bin/sh", "-c",
      "sudo add-apt-repository ppa:rmescandon/yq && sudo apt update && sudo apt install -y unzip curl git yq && /home/runner/run.sh",
    ]
  }
  set {
    name  = "template.spec.containers[0].env[0].name"
    value = "ACTIONS_RUNNER_CONTAINER_HOOKS"
  }
  set {
    name  = "template.spec.containers[0].env[0].value"
    value = "/home/runner/k8s/index.js"
  }
  set {
    name  = "template.spec.containers[0].env[1].name"
    value = "ACTIONS_RUNNER_POD_NAME"
  }
  set {
    name  = "template.spec.containers[0].env[1].valueFrom.fieldRef.fieldPath"
    value = "metadata.name"
  }
  set {
    name  = "template.spec.containers[0].env[2].name"
    value = "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER"
  }
  set {
    name  = "template.spec.containers[0].env[2].value"
    value = "\"true\""
  }
  set {
    name  = "template.spec.containers[0].env[3].name"
    value = "DISABLE_RUNNER_UPDATE"
  }
  set {
    name  = "template.spec.containers[0].env[3].value"
    value = "\"true\""
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
    name  = "template.spec.volumes[0].ephemeral.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
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

  depends_on = [
    helm_release.actions_runner_controller
  ]
}
