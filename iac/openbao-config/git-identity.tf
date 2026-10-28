# Git identity bank for Coder workspaces (see ../coder-template).
#
# Flow: coderd refreshes the workspace OWNER's Keycloak access token at every
# build and bakes it into the build metadata (coder_workspace_owner.me.
# oidc_access_token). The workspace startup script logs into OpenBao with it
# (role below) and reads the owner's git identities from
# secret/git-identities/<keycloak-username>/<identity>.
#
# This is the user-scoped auth path: no shared ServiceAccounts, no GitHub
# tokens — the identity is the Keycloak user, and the policy below scopes
# reads to that user's own paths via identity templating.

# JWT login role for workspace startup scripts. Same backend as the human
# OIDC login (auth/oidc), but role_type=jwt: direct token validation against
# the Keycloak realm JWKS — no browser round-trip.
resource "vault_jwt_auth_backend_role" "coder" {
  backend   = vault_jwt_auth_backend.oidc.path
  role_name = "coder"
  role_type = "jwt"

  # Keycloak access tokens carry NO `aud` claim (verified against the live
  # token), so bound_audiences is unusable here. `azp` names the client the
  # token was issued to — binding on it restricts logins to tokens minted
  # for Coder's client specifically.
  bound_claims = {
    azp = "coder"
  }

  # Alias name = Keycloak username -> per-user paths in the policy below.
  # (preferred_username is present in the access token; sub is a UUID, which
  # would make ugly paths.)
  user_claim = "preferred_username"

  token_policies = [vault_policy.git_identity.name]
  # Read-and-done at workspace start; 1h covers restarts within a session.
  token_ttl     = 3600
  token_max_ttl = 3600
}

resource "vault_policy" "git_identity" {
  name = "git-identity"

  policy = <<-EOT
    # Scoped to the logging-in user's own identity entries. The alias name is
    # the Keycloak username (role user_claim above), so a user can only ever
    # read secret/git-identities/<their-username>/*.
    path "secret/data/git-identities/{{identity.entity.aliases.${vault_jwt_auth_backend.oidc.accessor}.name}}" {
      capabilities = ["read"]
    }
    path "secret/data/git-identities/{{identity.entity.aliases.${vault_jwt_auth_backend.oidc.accessor}.name}}/*" {
      capabilities = ["read"]
    }
  EOT
}
