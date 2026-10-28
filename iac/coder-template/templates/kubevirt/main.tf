# KubeVirt VM workspaces — bespoke (no upstream template exists), modelled on
# the aws-linux example (VM + cloud-init agent injection) and the repo's own
# opnsense VM patterns. (Param tiers unified with the pod template.)
#
# Persistence model mirrors templates/default (pod workspaces): disposable
# root + persistent home.
#
#   - Root disk: `ephemeral` volume over the golden Ubuntu Noble image
#     (coder-workspace-ubuntu-noble in coder-workspaces, cloned once from
#     kubevirt-images by iac/coder/golden-image.tf). KubeVirt boots the
#     golden PVC read-only behind a per-VM COW overlay that is discarded on
#     stop, so every start is a pristine first boot: cloud-init runs fully
#     each time (fresh agent token, fresh packages), and template changes
#     reach existing workspaces on their next start.
#   - Home: a persistent PVC mounted at /home/coder — the only thing that
#     survives a stop.
#   - The Coder agent runs as a systemd unit (written fresh by cloud-init
#     each boot); the token rides in an EnvironmentFile. The token is NOT
#     embedded in coder_agent.main.init_script — pod templates inject it
#     separately, and so do we.
#   - docker.io is preinstalled each boot (~60-90s of apt); bake a golden
#     image with tools to skip that if it grates.
#   - RBAC for VirtualMachines is granted via the coder chart's
#     serviceAccount.workspaceNamespaces[].extraRules (iac/coder/coder.tf).
#
# Like templates/default, this file is NOT part of a tofu module: the coderd
# provider tars it up. Keep it `tofu fmt`-clean.

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
  description = "The Kubernetes namespace to create workspaces in."
  default     = "coder-workspaces"
}

variable "golden_pvc" {
  type        = string
  description = "Golden root image PVC (in the workspace namespace) that VMs boot ephemeral-style."
  default     = "coder-workspace-ubuntu-resolute"
}

variable "debug_ssh_authorized_key" {
  type        = string
  description = "Optional SSH public key granted to the coder user for break-glass debugging (empty disables)."
  default     = ""
}

# Tier generation (powers of two between bounds) — same pattern as
# templates/default. VM memory is fully reserved (requests = limits), so the
# floor is higher than the pod template's.
locals {
  cpu_min  = 2
  cpu_max  = 8
  cpu_tiers = [
    for i in range(0, floor(log(local.cpu_max / local.cpu_min, 2)) + 1) :
    local.cpu_min * pow(2, i)
  ]

  memory_min  = 4
  memory_max  = 32
  memory_tiers = [
    for i in range(0, floor(log(local.memory_max / local.memory_min, 2)) + 1) :
    local.memory_min * pow(2, i)
  ]
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores (pinned: requests = limits)"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true

  dynamic "option" {
    for_each = local.cpu_tiers

    content {
      name  = "${option.value} Cores"
      value = tostring(option.value)
    }
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB (fully reserved by the VM)"
  default      = "4"
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
  description  = "The size of the persistent home disk (/home/coder) in GB. Everything else is discarded when the workspace stops."
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 10
    max = 200
  }
}

data "coder_parameter" "claude_enabled" {
  name         = "claude_enabled"
  display_name = "Claude Code"
  description  = "Install the Claude Code CLI. Authenticate inside the workspace (claude -> /login): credentials persist on the home volume. No token is baked into the template."
  default      = "false"
  icon         = "/icon/claude.svg"
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

data "coder_parameter" "opencode_enabled" {
  name         = "opencode_enabled"
  display_name = "OpenCode"
  description  = "Install OpenCode and expose it as a workspace web app (via AgentAPI). Authenticate inside the workspace; credentials persist on the home volume."
  default      = "false"
  icon         = "/icon/opencode.svg"
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

provider "kubernetes" {
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  # VM boots are slower than pod starts (cloud-init + apt), give the agent
  # room before it is marked timed out.
  connection_timeout = 900

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
    key          = "2_home_disk"
    script       = "coder stat disk --path /home/coder"
    interval     = 60
    timeout      = 1
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

  # Persist code-server on the home disk (the module defaults to /tmp, which
  # is on the ephemeral root — a ~2GB redownload every start) and keep its
  # logs with the user's files.
  install_prefix = "/home/coder/.local/share/code-server"
  log_path       = "/home/coder/.cache/code-server.log"

  # Path apps are disabled on this deployment (CODER_DISABLE_PATH_APPS), so
  # code-server must be served on a workspace subdomain.
  subdomain = true
}

# Optional Claude Code CLI (registry.coder.com/modules/coder/claude-code).
# Auth is interactive inside the workspace — credentials land in ~/.claude
# on the persistent home. Deliberately NOT passing claude_code_oauth_token /
# anthropic_api_key: template-level tokens would live in tofu state and
# apply to every workspace.
module "claude-code" {
  count    = data.coder_parameter.claude_enabled.value == "true" ? 1 : 0
  source   = "registry.coder.com/coder/claude-code/coder"
  version  = "~> 1.2"
  agent_id = coder_agent.main.id
}

# Optional OpenCode with a dashboard web app (AgentAPI attaches to the TUI).
# Same auth story as claude-code: interactively inside the workspace.
module "opencode" {
  count     = data.coder_parameter.opencode_enabled.value == "true" ? 1 : 0
  source    = "registry.coder.com/coder-labs/opencode/coder"
  version   = "~> 0.1"
  agent_id  = coder_agent.main.id
  workdir   = "/home/coder"
  order     = 2
  subdomain = true
}

locals {
  cloud_init = <<-EOT
    #cloud-config
    hostname: ${data.coder_workspace.me.name}
    users:
      - name: coder
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: sudo
        shell: /bin/bash
        lock_passwd: true
        ssh_authorized_keys: ${var.debug_ssh_authorized_key != "" ? "[\"${var.debug_ssh_authorized_key}\"]" : "[]"}
    packages:
      - docker.io
    # The home PVC arrives BLANK (openebs zfs localpv does not preformat for
    # VM attachment). Format it in bootcmd — earliest cloud-init hook —
    # guarded by blkid so persistent data is never reformatted. (Tried the
    # fs_setup module first; it never runs on this image.)
    bootcmd:
      - [sh, -c, "blkid /dev/vdb || mkfs.ext4 -L coder-home /dev/vdb"]
      # Grow the root partition into the golden disk's full size (CDI
      # expands the imported image, but the partition table still needs
      # growing inside the guest; best-effort).
      - [sh, -c, "growpart /dev/vda 1 || true; resize2fs /dev/vda1 || true"]
    # cc_mounts runs before user creation, so /etc/skel is copied onto the
    # home disk by runcmd below.
    mounts:
      - [/dev/vdb, /home/coder, ext4, "defaults,nofail", "0", "2"]
    write_files:
      - path: /usr/local/bin/coder-agent-init.sh
        permissions: "0755"
        content: |
          ${indent(10, coder_agent.main.init_script)}
      - path: /etc/coder-agent.env
        permissions: "0600"
        content: |
          CODER_AGENT_TOKEN=${coder_agent.main.token}
      - path: /etc/systemd/system/coder-agent.service
        permissions: "0644"
        content: |
          [Unit]
          Description=Coder workspace agent
          Wants=network-online.target
          After=network-online.target
          [Service]
          User=coder
          # Not /home/coder: systemd turns WorkingDirectory into a mount
          # dependency, and the agent must start even if the home disk
          # (which may be blank on first start) fails to mount.
          WorkingDirectory=/
          EnvironmentFile=/etc/coder-agent.env
          ExecStart=/usr/local/bin/coder-agent-init.sh
          Restart=on-failure
          RestartSec=5
          [Install]
          WantedBy=multi-user.target
    runcmd:
      # Coder CLI on PATH: the code-server module's startup script and the
      # `coder stat` agent metadata both need it (the agent init script runs
      # the binary from a temp dir without installing it).
      - curl -fsSL https://coder.com/install.sh | sh
      # After packages: add the coder user to the freshly-created docker
      # group (users are created before packages, so it can't be a user
      # group at creation time).
      - adduser coder docker || true
      - cp -a /etc/skel/. /home/coder/ 2>/dev/null || true
      - chown -R coder:coder /home/coder
      - systemctl daemon-reload
      - systemctl enable --now coder-agent
  EOT

  # Cloud-init's fallback DHCP never configures the masquerade NIC on these
  # images, so pin KubeVirt's masquerade constants explicitly (from the
  # launcher's generated nft ruleset: guest 10.0.2.2, gateway 10.0.2.1 —
  # NOT QEMU slirp's 10.0.2.15/10.0.2.2). DNS bypasses 10.0.2.3 (the
  # launcher dnsmasq forwards to the node's systemd-resolved stub, which is
  # unreachable from the launcher netns).
  network_config = <<-EOT
    version: 2
    ethernets:
      all:
        match:
          name: "en*s0"
        addresses:
          - 10.0.2.2/24
        routes:
          - to: default
            via: 10.0.2.1
        nameservers:
          addresses:
            - 1.1.1.1
            - 9.9.9.9
  EOT
}

# Persistent home directory — the only disk that survives workspace restarts.
resource "kubernetes_persistent_volume_claim_v1" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
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

# Cloud-init lives in a Secret (the agent init script alone busts the 2048
# byte inline limit). The secret carries `userdata` + `networkdata` keys.
resource "kubernetes_secret_v1" "cloud_init" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-cloud-init"
    namespace = var.namespace
    labels = {
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
    }
  }

  data = {
    userdata    = local.cloud_init
    networkdata = local.network_config
  }
}

resource "kubernetes_manifest" "vm" {
  manifest = {
    apiVersion = "kubevirt.io/v1"
    kind       = "VirtualMachine"

    metadata = {
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

    spec = {
      # Workspace start/stop maps to VM power.
      running = data.coder_workspace.me.start_count == 1

      template = {
        spec = {
          architecture = "amd64"

          domain = {
            devices = {
              disks = [
                {
                  disk      = { bus = "virtio" }
                  name      = "rootdisk"
                  bootIndex = 1
                },
                {
                  disk = { bus = "virtio" }
                  name = "homedisk"
                },
                {
                  disk = { bus = "virtio" }
                  name = "cloudinit"
                }
              ]
              interfaces = [
                {
                  name = "default"
                  # `ports` (interface level) makes masquerade DNAT inbound 22
                  # for `virtctl ssh` / break-glass access.
                  ports      = [{ port = 22 }]
                  masquerade = {}
                }
              ]
            }

            resources = {
              requests = {
                memory = "${data.coder_parameter.memory.value}Gi"
                cpu    = "${data.coder_parameter.cpu.value}"
              }
              limits = {
                memory = "${data.coder_parameter.memory.value}Gi"
                cpu    = "${data.coder_parameter.cpu.value}"
              }
            }
          }

          networks = [
            {
              name = "default"
              pod  = {}
            }
          ]

          volumes = [
            {
              # Disposable root: golden image read-only + per-VM COW overlay,
              # discarded on stop. Same PVC serves every VM (single node, so
              # RWO multi-attach is fine).
              ephemeral = {
                persistentVolumeClaim = {
                  claimName = var.golden_pvc
                }
              }
              name = "rootdisk"
            },
            {
              persistentVolumeClaim = {
                claimName = kubernetes_persistent_volume_claim_v1.home.metadata[0].name
              }
              name = "homedisk"
            },
            {
              cloudInitNoCloud = {
                # KubeVirt v1 API: secretRef reads the secret's `userdata`
                # key; networkDataSecretRef its `networkdata` key. Both point
                # at the same secret.
                secretRef = {
                  name = kubernetes_secret_v1.cloud_init.metadata[0].name
                }
                networkDataSecretRef = {
                  name = kubernetes_secret_v1.cloud_init.metadata[0].name
                }
              }
              name = "cloudinit"
            }
          ]

          terminationGracePeriodSeconds = 60
        }
      }
    }
  }
}
