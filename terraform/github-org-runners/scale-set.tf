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

  set = [
    {
      name  = "githubConfigUrl"
      value = "https://github.com/${var.github_org_name}"
    },
    {
      name  = "githubConfigSecret.github_app_id"
      value = var.github_org_runners_app_id
    },
    {
      name  = "githubConfigSecret.github_app_installation_id"
      value = var.github_org_runners_app_installation_id
    },
    {
      name  = "maxRunners"
      value = "20"
    },
    {
      name  = "minRunners"
      value = "10"
    },
    {
      name  = "runnerScaleSetName"
      value = "self-hosted"
    },
    {
      name  = "containerMode.type"
      value = "kubernetes"
    },
    {
      name  = "containerMode.kubernetesModeWorkVolumeClaim.accessModes[0]"
      value = "ReadWriteOnce"
    },
    {
      name  = "containerMode.kubernetesModeWorkVolumeClaim.storageClassName"
      value = "openebs-zfs-localpv-general-no-backup"
    },
    {
      name  = "containerMode.kubernetesModeWorkVolumeClaim.resources.requests.storage"
      value = "1Gi"
    },
    {
      name  = "template.spec.initContainers[0].name"
      value = "chown-work"
    },
    {
      name  = "template.spec.initContainers[0].image"
      value = "alpine:3.22.2"
      }, {
      name  = "template.spec.initContainers[0].securityContext.runAsUser"
      value = "0"
    },
    {
      name  = "template.spec.initContainers[0].volumeMounts[0].name"
      value = "work"
    },
    {
      name  = "template.spec.initContainers[0].volumeMounts[0].mountPath"
      value = "/chown"
    },
    {
      name  = "template.spec.containers[0].name"
      value = "runner"
    },
    {
      name  = "template.spec.containers[0].image"
      value = "ghcr.io/jdc-projects/runner:${local.runner_version}"
    },
    {
      name  = "template.spec.containers[0].env[0].name"
      value = "ACTIONS_RUNNER_CONTAINER_HOOKS"
    },
    {
      name  = "template.spec.containers[0].env[0].value"
      value = "/home/runner/k8s/index.js"
    },
    {
      name  = "template.spec.containers[0].env[1].name"
      value = "ACTIONS_RUNNER_POD_NAME"
    },
    {
      name  = "template.spec.containers[0].env[1].valueFrom.fieldRef.fieldPath"
      value = "metadata.name"
    },
    {
      name  = "template.spec.containers[0].env[2].name"
      value = "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER"
    },
    {
      name  = "template.spec.containers[0].env[2].value"
      value = "\"true\""
    },
    {
      name  = "template.spec.containers[0].env[3].name"
      value = "DISABLE_RUNNER_UPDATE"
    },
    {
      name  = "template.spec.containers[0].env[3].value"
      value = "\"true\""
    },
    {
      name  = "template.spec.containers[0].volumeMounts[0].name"
      value = "work"
    },
    {
      name  = "template.spec.containers[0].volumeMounts[0].mountPath"
      value = "/home/runner/_work"
    },
    {
      name  = "template.spec.volumes[0].name"
      value = "work"
    },
    {
      name  = "template.spec.volumes[0].ephemeral.volumeClaimTemplate.spec.accessModes[0]"
      value = "ReadWriteOnce"
    },
    {
      name  = "template.spec.volumes[0].ephemeral.volumeClaimTemplate.spec.storageClassName"
      value = "openebs-zfs-localpv-general-no-backup"
    },
    {
      name  = "template.spec.volumes[0].ephemeral.volumeClaimTemplate.spec.resources.requests.storage"
      value = "1Gi"
    },
  ]


  set_sensitive = [
    {
      name  = "githubConfigSecret.github_app_private_key"
      value = var.github_org_runners_app_private_key
    }
  ]

  set_list = [
    {
      name = "template.spec.initContainers[0].command"
      value = [
        "sh", "-c",
        "chown -R ${local.runner_uid}:${local.runner_gid} /chown",
      ]
    },
    {
      name = "template.spec.containers[0].command"
      value = [
        "/bin/sh", "-c",
        "/home/runner/run.sh",
      ]
    },
  ]

  depends_on = [
    helm_release.actions_runner_controller
  ]
}
