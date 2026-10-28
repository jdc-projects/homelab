# CI authentication for this module: short-lived, per-run Kubernetes-auth
# tokens instead of a permanent root token in GitHub secrets.
#
# The deploy workflow (kubernetes-iac-deploy.yml, fetch-openbao-token input)
# mints a ServiceAccount token with `kubectl create token openbao-config` and
# feeds it to this provider via TF_VAR_openbao_token. The role below
# authorizes that SA against a scoped policy.
#
# Bootstrap note: the role/policy/SA below were originally created by the
# one-time root token (the role cannot authorize its own creation). The root
# token has since been revoked — emergency admin is the Keycloak SSO admin
# role (root-equivalent policy) or `bao operator generate-root` with the
# unseal key (OPENBAO_UNSEAL_KEY GitHub secret / in-cluster openbao-seal).

resource "kubernetes_service_account" "openbao_config" {
  metadata {
    name      = "openbao-config"
    namespace = "openbao"
  }
}

# What the provider manages here: auth methods (oidc, kubernetes), their
# config/roles, the secret/ KV mount, and ACL policies.
resource "vault_policy" "terraform" {
  name = "openbao-terraform"

  policy = <<-EOT
    path "sys/auth" {
      capabilities = ["read"]
    }

    path "sys/auth/oidc" {
      capabilities = ["create", "read", "update", "delete", "sudo"]
    }

    path "sys/auth/oidc/*" {
      capabilities = ["create", "read", "update", "delete", "sudo"]
    }

    path "sys/mounts/auth/*" {
      capabilities = ["create", "read", "update", "delete", "sudo"]
    }

    path "auth/oidc/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "auth/kubernetes" {
      capabilities = ["read"]
    }

    path "auth/kubernetes/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    # The provider mints a limited child token from the login token.
    path "auth/token/create" {
      capabilities = ["update"]
    }

    path "auth/token/create-orphan" {
      capabilities = ["update"]
    }

    path "sys/mounts" {
      capabilities = ["read"]
    }

    path "sys/mounts/secret*" {
      capabilities = ["create", "read", "update", "delete", "sudo"]
    }

    path "secret/" {
      capabilities = ["read"]
    }

    path "secret/*" {
      capabilities = ["read"]
    }

    path "sys/policies/acl" {
      capabilities = ["read"]
    }

    path "sys/policies/acl/openbao-admin" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "sys/policies/acl/openbao-terraform" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "sys/policies/acl/git-identity" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "openbao_config" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "openbao-config"
  bound_service_account_names      = [kubernetes_service_account.openbao_config.metadata[0].name]
  bound_service_account_namespaces = [kubernetes_service_account.openbao_config.metadata[0].namespace]

  audience       = "openbao"
  token_policies = [vault_policy.terraform.name]
  token_ttl      = 3600
}
