# The default workspace template, managed as code.
#
# The provider tars templates/default/ and pushes it to coderd exactly like
# `coder templates push` would. Version semantics: the provider hashes the
# directory itself and only creates a new template version when the contents
# change — but it requires the version *name* to change with the contents. So
# the name is derived from a content hash computed here: same content = same
# name = no-op apply, changed content = new active version. Running workspaces
# are left alone; users see an "update workspace" prompt.

locals {
  workspace_template_dir = "${path.module}/templates/default"

  # The hash covers every file in the template directory (flat; extend the
  # glob if subdirectories are ever introduced). README.md changes bump the
  # version too, since coderd serves it in the dashboard.
  workspace_template_files = fileset(local.workspace_template_dir, "*")

  workspace_template_hash = sha256(join("", [
    for f in sort(local.workspace_template_files) :
    filesha256("${local.workspace_template_dir}/${f}")
  ]))

  kubevirt_template_dir = "${path.module}/templates/kubevirt"

  kubevirt_template_files = fileset(local.kubevirt_template_dir, "*")

  kubevirt_template_hash = sha256(join("", [
    for f in sort(local.kubevirt_template_files) :
    filesha256("${local.kubevirt_template_dir}/${f}")
  ]))

  # Template-level terraform variable values for the kubevirt template
  # (e.g. debug_ssh_authorized_key). NOTE: folded into the version name —
  # the provider only creates a new version when the name changes, and a
  # tf_vars-only change doesn't alter the directory hash.
  kubevirt_version_vars = toset([])

  kubevirt_version_name = substr(sha256(join("|", [
    local.kubevirt_template_hash,
    jsonencode(sort([for v in local.kubevirt_version_vars : "${v.name}=${v.value}"])),
  ])), 0, 12)
}

resource "coderd_template" "default" {
  name         = "default"
  display_name = "Default (Kubernetes)"
  description  = "Pod workspaces on k3s. Home directory persists on a ZFS-backed PVC; everything else is rebuilt from the image."

  # Auto-stop workspaces after a working day of inactivity; users restart
  # from the dashboard or an autostart schedule.
  default_ttl_ms = 8 * 60 * 60 * 1000

  versions = [{
    directory = local.workspace_template_dir
    active    = true
    name      = substr(local.workspace_template_hash, 0, 12)
    message   = "Managed by OpenTofu (iac/coder-template)"
  }]

  # Enterprise-only fields (acl, auto_stop_requirement, dormant TTLs,
  # require_active_version, ...) are deliberately unset: AGPL deployment,
  # no license — the provider errors on them at apply time.
}

# KubeVirt VM workspaces — full Linux VMs (docker-in-docker ready). Bespoke
# template: no upstream to vendor; see templates/kubevirt/main.tf for the
# architecture (VM + DataVolume clone + cloud-init agent).
resource "coderd_template" "kubevirt" {
  name         = "kubevirt"
  display_name = "KubeVirt VM"
  description  = "Full Ubuntu VMs on k3s — real kernel, native docker, root disk persists across restarts."

  default_ttl_ms = 8 * 60 * 60 * 1000

  versions = [{
    directory = local.kubevirt_template_dir
    active    = true
    name      = local.kubevirt_version_name
    message   = "Managed by OpenTofu (iac/coder-template)"
    tf_vars   = local.kubevirt_version_vars
  }]
}
