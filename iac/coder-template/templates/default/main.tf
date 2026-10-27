# Vendored from registry.coder.com/templates/coder/kubernetes
# (github.com/coder/registry, registry/coder/templates/kubernetes), adapted for
# this cluster:
#
#   - `namespace` defaults to coder-workspaces, the dedicated workspace
#     namespace (coderd's service account is granted RBAC there by the helm
#     chart via coder.serviceAccount.workspaceNamespaces).
#   - The home PVC pins openebs-zfs-localpv-general: this cluster has NO
#     default StorageClass, so the upstream template's unpinned PVC would stay
#     Pending forever.
#   - code-server is a subdomain app (`subdomain = true`): path apps are
#     disabled deployment-wide (CODER_DISABLE_PATH_APPS=true), so a path-based
#     app would be unreachable.
#   - Memory options are generated parametrically: every power of two between
#     the bounds in `locals` below becomes a dropdown tier.
#   - Optional docker-in-docker sidecar (privileged `docker:29-dind` sharing
#     its socket with the workspace container via an emptyDir). Unprivileged
#     pods cannot run dockerd themselves (zero capabilities, read-only
#     cgroups/sysfs — verified empirically); the sidecar trades a privileged
#     container on the node for native `docker` in the workspace. Use the
#     kubevirt template to avoid that trade with full VMs.
#
# NOTE: this file is NOT part of a tofu module. The coderd provider in
# ../../coder-template/main.tf tars this directory and ships it to coderd,
# whose embedded provisioners execute it when template versions build and
# workspaces start. `tofu fmt -check` in CI does cover it (it lives under the
# coder-template module dir), so keep it formatted.

terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "coder" {
}

variable "use_kubeconfig" {
  type        = bool
  description = <<-EOF
    Use host kubeconfig? (true/false)

    Set this to false if the Coder host is itself running as a Pod on the same
    Kubernetes cluster as you are deploying workspaces to.

    Set this to true if the Coder host is running outside the Kubernetes cluster
    for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
    EOF
  default     = false
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces). If the Coder host is itself running as a Pod on the same Kubernetes cluster as you are deploying workspaces to, set this to the same namespace."
  default     = "coder-workspaces"
}

variable "image" {
  description = <<-EOF
    Container image for workspaces. The image determines which tools and
    languages are available in the workspace by default. See the template
    README for guidance on choosing an image.
    EOF
  type        = string
  default     = "codercom/example-base:ubuntu"
}

# Memory tiers for the workspace dropdown: every power of two from
# memory_min up to memory_max (GiB). Move either bound and the option list
# follows; non-power-of-two bounds floor to the tier below.
locals {
  memory_min  = 2
  memory_max  = 32
  memory_tiers = [
    for i in range(0, floor(log(local.memory_max / local.memory_min, 2)) + 1) :
    local.memory_min * pow(2, i)
  ]

  docker_cpu_min  = 2
  docker_cpu_max  = 8
  docker_cpu_tiers = [
    for i in range(0, floor(log(local.docker_cpu_max / local.docker_cpu_min, 2)) + 1) :
    local.docker_cpu_min * pow(2, i)
  ]

  docker_memory_min  = 2
  docker_memory_max  = 16
  docker_memory_tiers = [
    for i in range(0, floor(log(local.docker_memory_max / local.docker_memory_min, 2)) + 1) :
    local.docker_memory_min * pow(2, i)
  ]
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "6 Cores"
    value = "6"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true

  dynamic "option" {
    for_each = local.memory_tiers

    content {
      name  = "${option.value} GB"
      value = tostring(option.value)
    }
  }
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home disk size"
  description  = "The size of the home disk in GB"
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 1
    max = 99999
  }
}

data "coder_parameter" "docker_enabled" {
  name         = "docker_enabled"
  display_name = "Docker (dind sidecar)"
  description  = "Run a privileged docker-in-docker sidecar and expose its socket to the workspace. When disabled, the docker CPU/memory parameters have no effect."
  default      = "false"
  icon         = "/icon/docker.svg"
  mutable      = true
  option {
    name  = "Enabled"
    value = "true"
  }
  option {
    name  = "Disabled"
    value = "false"
  }
}

data "coder_parameter" "docker_cpu" {
  name         = "docker_cpu"
  display_name = "Docker CPU"
  description  = "CPU cores for the docker sidecar (only when docker is enabled)"
  default      = "2"
  icon         = "/icon/docker.svg"
  mutable      = true

  dynamic "option" {
    for_each = local.docker_cpu_tiers

    content {
      name  = "${option.value} Cores"
      value = tostring(option.value)
    }
  }
}

data "coder_parameter" "docker_memory" {
  name         = "docker_memory"
  display_name = "Docker memory"
  description  = "Memory in GB for the docker sidecar (only when docker is enabled)"
  default      = "4"
  icon         = "/icon/docker.svg"
  mutable      = true

  dynamic "option" {
    for_each = local.docker_memory_tiers

    content {
      name  = "${option.value} GB"
      value = tostring(option.value)
    }
  }
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }
}

# See https://registry.coder.com/modules/coder/code-server
module "code-server" {
  count  = data.coder_workspace.me.start_count
  source = "registry.coder.com/coder/code-server/coder"

  version  = "~> 1.0"
  agent_id = coder_agent.main.id
  order    = 1
  folder   = "/home/coder"

  # Path apps are disabled on this deployment (CODER_DISABLE_PATH_APPS), so
  # code-server must be served on a workspace subdomain (*-coder.<domain>) to
  # be reachable in a browser.
  subdomain = true
}

resource "kubernetes_persistent_volume_claim_v1" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      //Coder-specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace_owner.me.id
      "com.coder.user.username"  = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    # No default StorageClass exists in this cluster: pin the Velero-backed
    # app-data tier explicitly, or the PVC would never bind.
    storage_class_name = "openebs-zfs-localpv-general"
    resources {
      requests = {
        storage = "${data.coder_parameter.home_disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim_v1.home
  ]
  wait_for_rollout = false
  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "coder-workspace"
        "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
        "app.kubernetes.io/part-of"  = "coder"
        "com.coder.resource"         = "true"
        "com.coder.workspace.id"     = data.coder_workspace.me.id
        "com.coder.workspace.name"   = data.coder_workspace.me.name
        "com.coder.user.id"          = data.coder_workspace_owner.me.id
        "com.coder.user.username"    = data.coder_workspace_owner.me.name
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "coder-workspace"
          "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
          "app.kubernetes.io/part-of"  = "coder"
          "com.coder.resource"         = "true"
          "com.coder.workspace.id"     = data.coder_workspace.me.id
          "com.coder.workspace.name"   = data.coder_workspace.me.name
          "com.coder.user.id"          = data.coder_workspace_owner.me.id
          "com.coder.user.username"    = data.coder_workspace_owner.me.name
        }
      }
      spec {
        security_context {
          run_as_user     = 1000
          fs_group        = 1000
          run_as_non_root = true
        }

        container {
          name              = "dev"
          image             = var.image
          image_pull_policy = "IfNotPresent"
          command           = ["sh", "-c", coder_agent.main.init_script]
          security_context {
            run_as_user = "1000"
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "512Mi"
            }
            limits = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
            }
          }
          volume_mount {
            mount_path = "/home/coder"
            name       = "home"
            read_only  = false
          }

          # The dind socket directory (shared with the sidecar below) mounts
          # over /var/run so the preinstalled docker CLI finds it at the
          # standard path.
          dynamic "volume_mount" {
            for_each = data.coder_parameter.docker_enabled.value == "true" ? [1] : []

            content {
              mount_path = "/var/run"
              name       = "dind-sock"
            }
          }
        }

        # Privileged docker-in-docker sidecar. The workspace container cannot
        # run dockerd itself (unprivileged: zero capabilities, read-only
        # cgroups/sysfs), so the daemon runs here and shares its socket via
        # the dind-sock emptyDir. dockerd runs with `--group=1000` so the
        # socket is group-writable by the workspace's uid.
        dynamic "container" {
          for_each = data.coder_parameter.docker_enabled.value == "true" ? [1] : []

          content {
            name  = "dockerd"
            image = "docker:29-dind"
            args  = ["--group=1000"]

            security_context {
              privileged    = true
              run_as_user   = 0
              run_as_non_root = false
            }

            env {
              name  = "DOCKER_TLS_CERTDIR"
              value = ""
            }

            volume_mount {
              mount_path = "/var/run"
              name       = "dind-sock"
            }

            volume_mount {
              mount_path = "/var/lib/docker"
              name       = "dind-data"
            }

            resources {
              requests = {
                "cpu"    = "250m"
                "memory" = "512Mi"
              }
              limits = {
                "cpu"    = "${data.coder_parameter.docker_cpu.value}"
                "memory" = "${data.coder_parameter.docker_memory.value}Gi"
              }
            }
          }
        }

        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.home.metadata.0.name
            read_only  = false
          }
        }

        volume {
          name = "dind-sock"
          empty_dir {}
        }

        volume {
          name = "dind-data"
          empty_dir {
            # Image/layer storage for the sidecar; exceeding it evicts the
            # workspace pod (node ephemeral-storage limit).
            size_limit = "25Gi"
          }
        }

        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes. (Fixed vs the upstream registry template: the provider block
          // is preferred_during_scheduling_ignored_during_execution — upstream
          // ships "_in_execution", which fails coderd's provisioner parse.)
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
