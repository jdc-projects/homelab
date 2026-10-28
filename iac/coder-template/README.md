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
repo: the golden Ubuntu Noble image DataVolume (20Gi, URL-imported with CDI
so the image is expanded — `iac/coder/golden-image.tf`), VirtualMachine RBAC
via the chart's `serviceAccount.workspaceNamespaces[].extraRules`, and the
read-only `coder-crd-reader` ClusterRole for CRD schema discovery
(`iac/coder/crd-reader.tf`).

## Versioning

The provider only creates a new template version when the directory contents
change, and requires the version name to change with them — so the name is the
first 12 chars of a content hash over `templates/default/*`. Unchanged
content is a no-op apply. New active versions do **not** restart running
workspaces; users get an "update workspace" prompt.

## Git identities (OpenBao-backed)

Both templates expose a `git_identity` parameter (`none`/`personal`/`work`,
mutable). Non-`none` values run a startup script that logs the workspace
**owner** into OpenBao with the Keycloak OIDC token coderd bakes into every
build (`coder_workspace_owner.me.oidc_access_token` — refreshed per build,
30m lifespan via `../coder/keycloak.tf`), then reads
`secret/git-identities/<keycloak-username>/<identity>` and wires git:
name/email, SSH auth (`insteadOf` rewrites https://github.com/ to git@),
SSH commit signing (`gpg.format ssh`), known_hosts.

- **OpenBao side** (`../openbao-config/git-identity.tf`): `auth/oidc` role
  `coder` (role_type=jwt, `azp=coder` bound claim — Keycloak access tokens
  have no `aud`), policy `git-identity` scopes reads to
  `secret/git-identities/<self>/*` via identity templating.
- **Login must POST the role in the body** (`auth/oidc/login`, role param) —
  OpenBao 2.x doesn't register `login/<role>` as an unauthenticated route.
- **Identity entry shape** (KV v2): `name`, `email`, `ssh_private_key`,
  `ssh_public_key`. The key should be registered on GitHub as both an
  authentication and a signing key for Verified commits.
- The script never fails a workspace: no OIDC token (automation users like
  `tofu-deploy` have none), OpenBao unreachable, or missing entry → log +
  skip. Testing the full path therefore requires an OIDC-logged-in user's
  workspace.
- OpenBao is reached in-cluster only: `http://openbao.openbao.svc:8200`.

**Populating an identity** (one-time, per user). Either via the **Web UI**
(`https://bao.jd-chapman.dev/ui` → OIDC login → `secret/` → create secret at
`git-identities/<keycloak-user>/<identity>` with the fields below), or via
the OpenBao CLI. NOTE the binary collision: Homebrew's `bao` formula is the
unrelated Rust BAO hash tool; OpenBao's CLI is ALSO named `bao` and the two
formulas conflict — `brew uninstall bao && brew install openbao` if you want
the CLI and don't use the Rust tool. (`vault` CLI also works against OpenBao.)

```sh
export VAULT_ADDR=https://bao.jd-chapman.dev
bao login -method=oidc   # Keycloak SSO (openbao-admin)
bao kv put secret/git-identities/jack.chapman/personal \
  name='Jack Chapman' email=personal@example.com \
  ssh_private_key=@$HOME/.ssh/id_ed25519_personal \
  ssh_public_key=@$HOME/.ssh/id_ed25519_personal.pub
```

Notes:

- Use `@$HOME/...`, not `@~/...` — the `@` makes it a CLI file-argument, and
  the shell does not expand `~` mid-word.
- If the key has a passphrase, workspace git operations will prompt for it on
  every use (ssh-agent isn't running there). Prefer a passphrase-less copy in
  the bank: `cp ~/.ssh/id_ed25519_personal /tmp/git-personal && ssh-keygen -p
  -f /tmp/git-personal -P '<old>' -N ''` and upload that.
- Repeat for `work` with the work email and its own key (generate one if
  there isn't a dedicated key yet: `ssh-keygen -t ed25519 -N ''`).
- Register each pubkey on the matching GitHub account as **both** an
  authentication and a signing key (`gh ssh-key add --type signing` / web UI).
  If `id_ed25519_personal` already authenticates you to GitHub, only the
  signing-key registration is new.

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

## OpenCode workspaces (v2)

Both templates' optional OpenCode tooling deliberately avoids the registry
module and wires v2 itself:

- **Install**: the official v2 installer (`opencode.ai/v2/install`) runs on
  every start — always the latest stable v2, replacing any binary on the
  persistent home. (The legacy `opencode.ai/install` URL only serves the v1
  line, which is still maintained in parallel — don't "fix" the URL back.)
- **Web app without sign-in**: OpenCode v2 *always* enforces auth on its web
  UI — an empty `OPENCODE_PASSWORD` just regenerates one; there is no disable
  option (verified against 2.2.0: env scan, `service set`, serve flags, docs).
  Coder's app proxy can't inject headers, so the dashboard button points at a
  localhost nginx (`nginx-light`, per-start apt) on **13339** that stamps
  Basic auth onto every request (websockets included) before forwarding to
  `opencode serve` on **13338**. The browser never sees a sign-in screen.
- **Password**: generated once into `~/.opencode-password` (0600, persistent
  home) so sessions survive restarts; `cat ~/.opencode-password` if a client
  ever needs it. It never leaves the workspace.
- **nginx as non-root**: all five nginx temp-path directives must point into
  `~/.cache/nginx-tmp` — nginx mkdirs temp dirs for every proxy module at
  startup, and the compiled-in `/var/lib/nginx` defaults are root-only.
- The `[o]pencode serve` pkill bracket trick is load-bearing: startup scripts
  run via `sh -c`, so an unbracketed pattern matches the script itself.

## Application of this module

Standard flow: commit to trunk → `utils/check-tf-locks.sh` →
`gh workflow run deploy.yml -f runner-type=self-hosted` (`deploy-coder-template`
job). Local runs work like any other module — the provider uses the public
dashboard URL and reads the token from the coder state output.
