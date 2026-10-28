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

```bash
export TF_VAR_openbao_root_token="$(kubectl -n openbao get secret openbao-bootstrap -o jsonpath='{.data.root-token}' | base64 -d)"
tofu apply -var "server_base_domain=<domain>"
```

## TODO

- **Switch to the dedicated `openbao` OpenTofu provider once it ships** (an
  accepted RFC upstream; low-divergence soft-fork of `hashicorp/vault` with a
  `tofu state replace-provider` migration path). `hashicorp/vault` covers
  everything used here until then; known incompatibilities are in areas this
  repo doesn't use (e.g. `auth_login_aws`).
- **Replace the root token with Kubernetes-auth** for this provider (mint a
  short-lived SA token via `kubectl create token` in a workflow pre-step)
  and **revoke the root token** (`bao token revoke <token>`).
- Add per-app `vault_kubernetes_auth_backend_role`s + narrow policies when
  applications start consuming OpenBao (the agent injector in `iac/openbao`
  is deliberately off until then).
