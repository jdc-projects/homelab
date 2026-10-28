# OpenBao configuration

Post-deploy configuration for OpenBao (deployed by `iac/openbao`), mirroring
`keycloak`/`keycloak-config`:

- **Keycloak**: `openbao` OIDC client (confidential, standard flow) with a
  `groups` claim mapper. Redirect URIs cover the UI
  (`/ui/vault/auth/oidc/oidc/callback` — OpenBao keeps Vault's `/ui/vault/`
  path), the direct API callback, and the CLI localhost listener
  (`bao login -method=oidc`).
- **OpenBao** (via `hashicorp/vault` provider against the root token):
  - `auth/oidc` — human logins; the `admin` role bound_claims on
    `groups = system_admins` and maps to the root-equivalent `openbao-admin`
    policy (SSO replaces root logins).
  - `auth/kubernetes` — foundation for app auth (per-app roles when the first
    consumer lands).
  - `secret/` KV v2 mount + file audit device.

## Applying locally

The provider's Kubernetes-auth JWT is minted inside tofu (external data
source in `main.tf`), so local applies need nothing special — just the usual
`cluster.yml` next to the module:

```bash
tofu apply -var "server_base_domain=<domain>"
```

(The minted token lands in tofu state; accepted trade-off — it is ≤1h and
scoped to the `openbao-config` role.)

## Bootstrap / recovery

There is no standing root credential (revoked after first bootstrap). If the
role/SA/policy ever needs recreating from scratch: temporarily replace the
provider's `auth_login_jwt` block with `token = <token>` — a token minted by
an SSO admin (`bao login -method=oidc`, root-equivalent policy) or, worst
case, `bao operator generate-root` with the unseal key — apply once, then
restore the block.

## TODO

- **Switch to the dedicated `openbao` OpenTofu provider once it ships** (an
  accepted RFC upstream; low-divergence soft-fork of `hashicorp/vault` with a
  `tofu state replace-provider` migration path). `hashicorp/vault` covers
  everything used here until then; known incompatibilities are in areas this
  repo doesn't use (e.g. `auth_login_aws`) — plus the audit-device API
  removal already worked around in `iac/openbao`.
- Add per-app `vault_kubernetes_auth_backend_role`s + narrow policies when
  applications start consuming OpenBao (the agent injector in `iac/openbao`
  is deliberately off until then).
