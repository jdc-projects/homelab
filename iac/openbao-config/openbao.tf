# Human access: OIDC via Keycloak. The admin role gates on the `groups` claim
# (system_admins, from LDAP federation) and maps to the broad openbao-admin
# policy — the SSO replacement for root logins.
resource "vault_jwt_auth_backend" "oidc" {
  description = "Keycloak OIDC (human logins via UI/CLI)"
  path        = "oidc"
  type        = "oidc"

  oidc_discovery_url = data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url
  oidc_client_id     = keycloak_openid_client.openbao.client_id
  oidc_client_secret = random_password.keycloak_client_secret.result

  default_role = "admin"
}

resource "vault_jwt_auth_backend_role" "admin" {
  backend   = vault_jwt_auth_backend.oidc.path
  role_name = "admin"
  role_type = "oidc"

  allowed_redirect_uris = local.oidc_redirect_uris

  user_claim   = "sub"
  groups_claim = "groups"
  bound_claims = {
    groups = "system_admins"
  }

  token_policies = [vault_policy.openbao_admin.name]
  # Seconds (provider v5): 1h TTL, 4h max.
  token_ttl     = 3600
  token_max_ttl = 14400

  oidc_scopes = ["profile", "email"]
}

resource "vault_policy" "openbao_admin" {
  name = "openbao-admin"

  policy = <<-EOT
    # Single-admin homelab: the SSO admin role is root-equivalent by design.
    path "*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo", "patch"]
    }
  EOT
}

# Machine access: Kubernetes auth so in-cluster apps can authenticate with
# their ServiceAccount tokens (consumer roles are added per-app when the
# first one adopts OpenBao — see iac/openbao README).
resource "vault_auth_backend" "kubernetes" {
  description = "In-cluster service accounts"
  type        = "kubernetes"
  path        = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc:443"

  # reviewer_jwt / kubernetes_ca_cert left unset: OpenBao uses its own pod's
  # SA token and CA bundle; the chart's authDelegator ClusterRoleBinding
  # permits the TokenReviews this requires.
}

# General-purpose KV v2 mount for application secrets.
resource "vault_mount" "kv" {
  description = "Application secrets (KV v2)"
  path        = "secret"
  type        = "kv"

  options = {
    version = "2"
  }
}

# NOTE: the audit device is NOT managed here — OpenBao 2.x removed the
# sys/audit API ("use declarative, config-based audit device management
# instead"), so the vault provider's vault_audit resource fails. It is
# declared in iac/openbao's server config instead (audit "file" "file" stanza).
# A concrete example of the Vault/OpenBao provider divergence that the
# dedicated openbao provider (see README TODO) is meant to address.
