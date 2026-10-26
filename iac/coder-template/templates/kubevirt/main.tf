# KubeVirt VM workspaces — bespoke (no upstream template exists), modelled on
# the aws-linux example (VM + cloud-init agent injection) and the repo's own
# opnsense VM patterns.
#
#   - Each workspace is a kubevirt.io/v1 VirtualMachine in coder-workspaces
#     with `running` driven by workspace start/stop: stop = VM off, disk kept.
#   - The root disk is a DataVolume cloned from the golden Ubuntu Noble cloud
#     image PVC in kubevirt-images (imported by iac/kubevirt/images.tf).
#     Cross-namespace clone auth: iac/kubevirt/coder-workspace-clone-auth.tf.
#   - The Coder agent is injected via cloud-init (write_files + runcmd), and
#     docker.io is preinstalled: workspaces run real containers natively —
#     the docker-in-docker motivation for VMs.
#   - RBAC for VirtualMachines/DataVolumes is granted via the coder chart's
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

variable "base_image_namespace" {
  type        = string
  description = "Namespace of the golden image PVC that workspace root disks are cloned from."
  default     = "kubevirt-images"
}

variable "base_image_pvc" {
  type        = string
  description = "Name of the golden image PVC that workspace root disks are cloned from."
  default     = "ubuntu-noble-server-cloudimg-amd64"
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

data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Root disk size"
  description  = "The size of the VM root disk in GB (set at creation; the whole disk persists)"
  default      = "30"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 10
    max = 200
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

  # VMs are slow to come up: DataVolume clone + boot + cloud-init + docker
  # install routinely takes a few minutes on first start.
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
    display_name = "Root Disk"
    key          = "2_root_disk"
    script       = "coder stat disk --path /"
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

  # Path apps are disabled on this deployment (CODER_DISABLE_PATH_APPS), so
  # code-server must be served on a workspace subdomain.
  subdomain = true
}

variable "debug_ssh_authorized_key" {
  type        = string
  description = "Optional SSH public key granted to the coder user for break-glass debugging (empty disables)."
  default     = ""
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
    write_files:
      # Agent launcher: cloud-init's per-instance modules (runcmd) run only on
      # the FIRST boot of a workspace's disk, and coder rebuilds rotate the
      # embedded agent token — so the service re-syncs the script from the
      # cloud-init seed ISO (regenerated with a fresh token at every VM start)
      # before starting. Markers are what the sync script extracts.
      - path: /usr/local/bin/coder-agent-init.sh
        permissions: "0755"
        content: |
          ### CODER-AGENT-BEGIN ###
          ${indent(10, coder_agent.main.init_script)}
          ### CODER-AGENT-END ###
      - path: /usr/local/lib/coder-agent-sync.sh
        permissions: "0755"
        content: |
          ### CODER-SYNC-BEGIN ###
          #!/bin/sh
          # Re-extract the agent init + sync scripts from the cloud-init seed
          # ISO (/dev/vdb), which KubeVirt regenerates from the workspace
          # Secret at every VM start. Keeps the on-disk scripts (and their
          # embedded agent token) fresh across rebuilds. Also clears the init
          # script's leaked download temp dirs (its retry loop never reuses
          # them).
          set -e
          rm -rf /tmp/coder.?????? 2>/dev/null || true
          MNT="$1"
          extract() {
            awk -v b="### $1 ###" -v e="### $2 ###" 'index($0,b){f=1;next} index($0,e){f=0} f' "$MNT/user-data" \
              | sed -e 's/^          //' -e '1s/^[[:space:]]*//' > "$3.new"
            [ -s "$3.new" ] || exit 1
            chmod 0755 "$3.new"
            mv "$3.new" "$3"
          }
          if [ -f "$MNT/user-data" ]; then
            extract CODER-SYNC-BEGIN CODER-SYNC-END /usr/local/lib/coder-agent-sync.sh
            extract CODER-AGENT-BEGIN CODER-AGENT-END /usr/local/bin/coder-agent-init.sh
            extract CODER-TOKEN-BEGIN CODER-TOKEN-END /etc/coder-agent.env
            chmod 0600 /etc/coder-agent.env
            UNIT_OLD=$(cat /etc/systemd/system/coder-agent.service 2>/dev/null)
            extract CODER-UNIT-BEGIN CODER-UNIT-END /etc/systemd/system/coder-agent.service
            [ "$UNIT_OLD" = "$(cat /etc/systemd/system/coder-agent.service)" ] || systemctl daemon-reload
          fi
          ### CODER-SYNC-END ###
      # The agent token is NOT embedded in init_script — inject it via an
      # EnvironmentFile that the sync script refreshes from the seed on every
      # boot (tokens rotate per build).
      - path: /etc/coder-agent.env
        permissions: "0600"
        content: |
          ### CODER-TOKEN-BEGIN ###
          CODER_AGENT_TOKEN=${coder_agent.main.token}
          ### CODER-TOKEN-END ###
      - path: /etc/systemd/system/coder-agent.service
        permissions: "0644"
        content: |
          ### CODER-UNIT-BEGIN ###
          [Unit]
          Description=Coder workspace agent
          Wants=network-online.target
          After=network-online.target
          [Service]
          User=coder
          WorkingDirectory=/home/coder
          EnvironmentFile=/etc/coder-agent.env
          # Mount helper + sync run as root; the agent itself as coder.
          ExecStartPre=+/bin/sh -c 'MNT=$(mktemp -d); mount -o ro /dev/vdb $MNT && /usr/local/lib/coder-agent-sync.sh $MNT; umount $MNT; rmdir $MNT'
          ExecStart=/usr/local/bin/coder-agent-init.sh
          Restart=on-failure
          RestartSec=5
          [Install]
          WantedBy=multi-user.target
          ### CODER-UNIT-END ###
    runcmd:
      - adduser coder docker || true
      - systemctl enable --now docker
      - systemctl daemon-reload
      - systemctl enable --now coder-agent
  EOT

  # Cloud-init's fallback DHCP never configures the masquerade NIC on these
  # images, so pin KubeVirt's masquerade constants explicitly (from the
  # launcher's generated nft ruleset: guest 10.0.2.2, gateway 10.0.2.1 —
  # NOT QEMU slirp's 10.0.2.15/10.0.2.2). DNS bypasses 10.0.2.3 (the
  # launcher dnsmasq forwards to the node's systemd-resolved stub, which is
  # unreachable from the launcher netns). The netplan file persists on the
  # workspace disk, so later boots don't need cloud-init to re-apply it.
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

# KubeVirt rejects inline cloud-init over 2048 bytes (the agent init script
# alone is bigger), so it lives in a Secret referenced by secretRef. The
# secret carries both `userdata` and `networkdata` keys, which cloudInitNoCloud
# picks up from the same reference.
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
      # Workspace start/stop maps to VM power: stop keeps the root disk.
      running = data.coder_workspace.me.start_count == 1

      dataVolumeTemplates = [
        {
          metadata = {
            name = "coder-${data.coder_workspace.me.id}-root"
          }
          spec = {
            source = {
              pvc = {
                namespace = var.base_image_namespace
                name      = var.base_image_pvc
              }
            }
            storage = {
              resources = {
                requests = {
                  storage = "${data.coder_parameter.disk_size.value}Gi"
                }
              }
              storageClassName = "openebs-zfs-localpv-general"
              accessModes      = ["ReadWriteOnce"]
            }
          }
        }
      ]

      template = {
        spec = {
          architecture = "amd64"

          domain = {
            devices = {
              disks = [
                {
                  disk = { bus = "virtio" }
                  name = "rootdisk"
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
              dataVolume = { name = "coder-${data.coder_workspace.me.id}-root" }
              name       = "rootdisk"
            },
            {
              cloudInitNoCloud = {
                # KubeVirt v1 API: secretRef reads the secret's `userdata`
                # key; networkDataSecretRef its `networkdata` key. Both point
                # at the same secret. (The 2048-byte inline limit forces the
                # Secret route for the agent init script.)
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
