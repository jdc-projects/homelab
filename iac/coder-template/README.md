# Coder workspace templates

Manages Coder's workspace templates as code via the official
[`coder/coderd`](https://registry.terraform.io/providers/coder/coderd) provider —
the same thing `coder templates push` does, but through tofu, so template
deploys ride the normal deploy workflow.

**Separate module from `iac/coder` on purpose:** the provider talks to the live
coderd API, including at plan time (state refresh reads the template back over
HTTP). `iac/coder` must stay plannable while coderd is down (first bootstrap,
DB hibernation), so template management cannot live there. `deploy.yml` runs
this module after `deploy-bulk` (which includes `iac/coder`) has converged.

| Piece     | What                                                                                       |
| --------- | ------------------------------------------------------------------------------------------ |
| Template  | `default` — vendored from [registry.coder.com/templates/coder/kubernetes](https://registry.coder.com/templates/coder/kubernetes), see `templates/default/` |
| Template  | `kubevirt` — bespoke VM workspaces (full Linux VM, native docker), see `templates/kubevirt/` |

The kubevirt template depends on extra infrastructure, all deployed by this
repo: the golden Ubuntu Noble image PVC (`iac/kubevirt/images.tf`), the CDI
cross-namespace clone-auth Role (`iac/kubevirt/coder-workspace-clone-auth.tf`),
VirtualMachine/DataVolume RBAC via the chart's
`serviceAccount.workspaceNamespaces[].extraRules`, and the read-only
`coder-crd-reader` ClusterRole for CRD schema discovery (`iac/coder/crd-reader.tf`).

## Versioning

The provider only creates a new template version when the directory contents
change, and requires the version name to change with them — so the name is the
first 12 chars of a content hash over `templates/default/*`. Unchanged
content is a no-op apply. New active versions do **not** restart running
workspaces; users get an "update workspace" prompt.

## Auth (auto-minted)

No GitHub secrets, no manual logins. The `iac/coder` bootstrap job
(`../coder/bootstrap.tf`, sentry-style) mints an owner API token from inside
the deployment and exports it as the `coder_api_token` state output; this
module consumes it via `terraform_remote_state`. Rotation: delete the
`coder-api-token` Secret and re-run the coder module — the job re-mints. The
token lives in tofu state, the same trust model as `sentry_auth_token` /
`keycloak_admin_password`.

## Template tweaks vs upstream

- `namespace` defaults to `coder-workspaces` (RBAC granted by the coder chart's
  `coder.serviceAccount.workspaceNamespaces` value — see `iac/coder/coder.tf`).
- Home PVC pins `openebs-zfs-localpv-general`: the cluster has **no default
  StorageClass**, so the upstream template's unpinned PVC would stay Pending
  forever.
- code-server runs with `subdomain = true`: path apps are disabled
  deployment-wide (`CODER_DISABLE_PATH_APPS`), so a path-based app would be
  unreachable.

## Application of this module

Standard flow: commit to trunk → `utils/check-tf-locks.sh` →
`gh workflow run deploy.yml -f runner-type=self-hosted` (`deploy-coder-template`
job). Local runs work like any other module — the provider uses the public
dashboard URL and reads the token from the coder state output.
