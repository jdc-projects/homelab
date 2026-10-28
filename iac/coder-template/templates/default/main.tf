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
  default     = "codercom/example-universal:ubuntu"
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

  # Main-container CPU tiers, kept in a local so the docker sidecar parameter
  # offers the identical list (the upstream template's tiers — 6 is not a
  # power of two, hence an explicit list rather than the memory-tiers
  # parametric generation above).
  cpu_tiers = [2, 4, 6, 8]
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
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

data "coder_parameter" "git_identity" {
  name         = "git_identity"
  display_name = "Git identity"
  description  = "Configure git (name, email, SSH auth + SSH commit signing) at startup from OpenBao: secret/git-identities/<your-keycloak-user>/<identity>. 'None' leaves git unconfigured."
  default      = "none"
  icon         = "/icon/git.svg"
  mutable      = true

  option {
    name  = "None (leave git unconfigured)"
    value = "none"
  }
  option {
    name  = "Personal"
    value = "personal"
  }
  option {
    name  = "Work"
    value = "work"
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
    for_each = local.cpu_tiers

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
    for_each = local.memory_tiers

    content {
      name  = "${option.value} GB"
      value = tostring(option.value)
    }
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

# Optional OpenCode v2 (opencode.ai) with its native web app. Deliberately
# not the registry module (registry.coder.com/coder-labs/opencode): that one
# wraps the TUI in AgentAPI (a browser-terminal mirror that renders the
# opencode TUI poorly) and its installer SKIPS when a binary exists —
# freezing the version forever on our persistent homes. Instead: run the
# official V2 installer on EVERY start (Claude-Code-module style — always
# the latest stable v2) and serve the web UI.
#
# OpenCode v2 ALWAYS enforces auth on its web UI (empty password just
# regenerates one; there is no disable option — verified against 2.2.0).
# Coder's app proxy can't inject headers, so the dashboard button points at
# a localhost nginx that stamps Basic auth onto every request (websockets
# included) before forwarding to `opencode serve`. The browser never sees a
# sign-in screen; Coder still authenticates the user in front; the password
# never leaves the workspace.
#
#   Coder proxy -> 127.0.0.1:13339 (nginx, injects auth) -> 127.0.0.1:13338 (serve)
#
# State on the persistent home: the password at ~/.opencode-password
# (generated once; `cat ~/.opencode-password` if a client ever asks for
# it), auth/config under ~/.local/share/opencode. Only the binary and the
# nginx config are refreshed per start.
resource "coder_script" "opencode" {
  count        = data.coder_parameter.opencode_enabled.value == "true" ? 1 : 0
  agent_id     = coder_agent.main.id
  display_name = "OpenCode"
  icon         = "/icon/opencode.svg"

  script = <<-EOT
    #!/usr/bin/env sh
    set -eu
    # Always run the official v2 installer: fetches the latest stable v2
    # and replaces any existing binary.
    curl -fsSL https://opencode.ai/v2/install | bash
    mkdir -p "$HOME/.cache" "$HOME/.opencode"

    # Stable web-UI password on the persistent home: v2 requires auth no
    # matter what, so generate once and reuse forever — sessions survive
    # restarts instead of dying with every regenerated password.
    if [ ! -s "$HOME/.opencode-password" ]; then
      (LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 40) \
        > "$HOME/.opencode-password"
      chmod 600 "$HOME/.opencode-password"
    fi
    PW="$(cat "$HOME/.opencode-password")"

    # nginx: auth-injecting proxy for the web UI (see comment above).
    SUDO=""
    [ "$(id -u)" = 0 ] || SUDO="sudo"
    $SUDO apt-get update -qq
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx-light
    NGINX_BIN="$(command -v nginx || echo /usr/sbin/nginx)"
    BASIC="$(printf 'opencode:%s' "$PW" | base64)"
    # All five temp paths must be overridden: nginx mkdirs them for every
    # proxy module at startup (not just the ones in use), and the compiled-in
    # defaults under /var/lib/nginx are root-only.
    mkdir -p "$HOME/.cache/nginx-tmp/body" "$HOME/.cache/nginx-tmp/proxy" \
      "$HOME/.cache/nginx-tmp/fastcgi" "$HOME/.cache/nginx-tmp/uwsgi" \
      "$HOME/.cache/nginx-tmp/scgi"
    cat > "$HOME/.opencode/nginx.conf" <<CONF
    pid $HOME/.cache/opencode-nginx.pid;
    error_log $HOME/.cache/opencode-nginx-error.log;
    events { worker_connections 128; }
    http {
      access_log off;
      client_body_temp_path $HOME/.cache/nginx-tmp/body;
      proxy_temp_path $HOME/.cache/nginx-tmp/proxy;
      fastcgi_temp_path $HOME/.cache/nginx-tmp/fastcgi;
      uwsgi_temp_path $HOME/.cache/nginx-tmp/uwsgi;
      scgi_temp_path $HOME/.cache/nginx-tmp/scgi;
      map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ''      close;
      }
      server {
        listen 127.0.0.1:13339;
        location / {
          proxy_pass http://127.0.0.1:13338;
          proxy_http_version 1.1;
          proxy_set_header Upgrade \$http_upgrade;
          proxy_set_header Connection \$connection_upgrade;
          proxy_set_header Authorization "Basic $BASIC";
          proxy_buffering off;
          proxy_request_buffering off;
          proxy_read_timeout 3600s;
        }
      }
    }
    CONF

    # Restart-not-reboot safe: kill a previous serve and nginx first.
    pkill -f "[o]pencode serve" 2>/dev/null || true
    if [ -f "$HOME/.cache/opencode-nginx.pid" ]; then
      kill "$(cat "$HOME/.cache/opencode-nginx.pid")" 2>/dev/null || true
    fi

    OPENCODE_PASSWORD="$PW" nohup "$HOME/.opencode/bin/opencode" serve --port 13338 \
      > "$HOME/.cache/opencode-serve.log" 2>&1 &
    nohup "$NGINX_BIN" -c "$HOME/.opencode/nginx.conf" >/dev/null 2>&1 &
  EOT

  run_on_start = true
}

resource "coder_app" "opencode" {
  count        = data.coder_parameter.opencode_enabled.value == "true" ? 1 : 0
  agent_id     = coder_agent.main.id
  slug         = "opencode"
  display_name = "OpenCode"
  url          = "http://localhost:13339"
  icon         = "/icon/opencode.svg"
  subdomain    = true
  share        = "owner"
  order        = 2

  healthcheck {
    url       = "http://localhost:13339"
    interval  = 10
    threshold = 15
  }
}

# Git identity from OpenBao (per-user bank). coderd refreshes the workspace
# OWNER's Keycloak access token at every build and bakes it into this script
# at provision time (data.coder_workspace_owner.me.oidc_access_token); the
# script logs into OpenBao with it (auth/oidc role "coder" — azp-bound JWT
# login, user-scoped via the git-identity policy in iac/openbao-config) and
# reads secret/git-identities/<keycloak-username>/<identity>: {name, email,
# ssh_private_key, ssh_public_key}. The selected identity wires git identity
# + SSH auth + SSH signing (gpg.format ssh) — one key registered on GitHub as
# both an authentication and a signing key shows commits as Verified.
#
# Graceful skips (exit 0, never fails the workspace): no OIDC token (owner
# not OIDC-logged-in / automation user), OpenBao unreachable/login failure,
# or the identity entry not populated yet.
# OpenBao is reached in-cluster only: http://openbao.openbao.svc:8200.
resource "coder_script" "git_identity" {
  count        = data.coder_parameter.git_identity.value != "none" ? 1 : 0
  agent_id     = coder_agent.main.id
  display_name = "Git identity (OpenBao)"
  icon         = "/icon/git.svg"

  script = <<-EOT
    #!/usr/bin/env sh
    set -eu
    IDENTITY="${data.coder_parameter.git_identity.value}"
    JWT="${data.coder_workspace_owner.me.oidc_access_token}"
    BAO="http://openbao.openbao.svc:8200"

    if [ -z "$JWT" ]; then
      echo "No OIDC token for this workspace owner (automation user, or no"
      echo "recent Keycloak login) - skipping git identity."
      exit 0
    fi

    command -v jq >/dev/null 2>&1 || {
      SUDO=""
      [ "$(id -u)" = 0 ] || SUDO="sudo"
      $SUDO apt-get update -qq
      $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq jq
    }

    # NOTE: role goes in the BODY, not the path — OpenBao 2.x only registers
    # auth/<mount>/login (exact) as an unauthenticated route; /login/<role>
    # falls through to ACL checks and unauthenticated callers get "permission
    # denied" regardless of role existence.
    RESP=$(curl -s --max-time 15 -X POST "$BAO/v1/auth/oidc/login" \
      -H "Content-Type: application/json" \
      -d "{\"role\":\"coder\",\"jwt\":\"$JWT\"}")
    VT=$(printf '%s' "$RESP" | jq -r '.auth.client_token // empty')
    if [ -z "$VT" ]; then
      echo "OpenBao login failed - skipping git identity:"
      printf '%s' "$RESP" | jq -r '.errors[]?' 2>/dev/null | head -3
      exit 0
    fi
    USER_=$(printf '%s' "$RESP" | jq -r '.auth.alias.name')
    echo "OpenBao login OK (user: $USER_)"

    SECRET=$(curl -s --max-time 15 -H "X-Vault-Token: $VT" \
      "$BAO/v1/secret/data/git-identities/$USER_/$IDENTITY")
    NAME=$(printf '%s' "$SECRET" | jq -r '.data.data.name // empty')
    EMAIL=$(printf '%s' "$SECRET" | jq -r '.data.data.email // empty')
    PRIVKEY=$(printf '%s' "$SECRET" | jq -r '.data.data.ssh_private_key // empty')
    PUBKEY=$(printf '%s' "$SECRET" | jq -r '.data.data.ssh_public_key // empty')
    if [ -z "$NAME" ] || [ -z "$EMAIL" ] || [ -z "$PRIVKEY" ] || [ -z "$PUBKEY" ]; then
      echo "Identity '$IDENTITY' not found (or incomplete) at"
      echo "git-identities/$USER_/$IDENTITY in OpenBao."
      echo "Populate it and restart the workspace - skipping git identity."
      exit 0
    fi

    mkdir -p "$HOME/.ssh"
    KEY="$HOME/.ssh/git-$IDENTITY"
    printf '%s\n' "$PRIVKEY" > "$KEY"
    printf '%s\n' "$PUBKEY" > "$KEY.pub"
    chmod 600 "$KEY"
    chmod 644 "$KEY.pub"

    # Replace any previous managed block, then append this identity's.
    touch "$HOME/.ssh/config"
    sed -i '/# --- coder git-identity (managed)/,/# --- end coder git-identity/d' "$HOME/.ssh/config"
    cat >> "$HOME/.ssh/config" <<SSHCFG
    # --- coder git-identity (managed) ---
    Host github.com
      IdentityFile $KEY
      IdentitiesOnly yes
    # --- end coder git-identity ---
SSHCFG

    grep -q 'github.com ssh-ed25519' "$HOME/.ssh/known_hosts" 2>/dev/null || \
      ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

    git config --global user.name "$NAME"
    git config --global user.email "$EMAIL"
    git config --global user.signingkey "$KEY.pub"
    git config --global gpg.format ssh
    git config --global commit.gpgsign true
    # Transparently authenticate https://github.com/ clones with the key.
    git config --global url."git@github.com:".insteadOf "https://github.com/"

    echo "Git identity '$IDENTITY' configured ($NAME <$EMAIL>)."
    echo "If commits show Unverified / pushes are rejected, register this key"
    echo "on GitHub (Settings > SSH keys) as BOTH an authentication and a"
    echo "signing key:"
    cat "$KEY.pub"
  EOT

  run_on_start = true
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
