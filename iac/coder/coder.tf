locals {
  coder_domain = "coder.${var.server_base_domain}"

  # Workspace-app hostnames: <app>--<workspace>--<user>-coder.<domain>
  # (single label, so the zone wildcard DNS + TLS cert cover it — see ingress.tf).
  coder_suffix_wildcard = "*-coder.${var.server_base_domain}"

  otel_endpoint = "http://otel-collector.otel.svc:4318"
}

# Connection URL consumed by the helm chart via CODER_PG_CONNECTION_URL.
resource "kubernetes_secret" "coder_db_url" {
  metadata {
    name      = "coder-db-url"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }

  data = {
    url = "postgresql://${random_password.coder_db_username.result}:${random_password.coder_db_password.result}@${kubernetes_manifest.coder_db.manifest.metadata.name}-rw:5432/coder?sslmode=disable"
  }
}

resource "kubernetes_secret" "coder_oidc" {
  metadata {
    name      = "coder-oidc"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }

  data = {
    client-secret = random_password.keycloak_client_secret.result
  }
}

resource "helm_release" "coder" {
  name       = "coder"
  namespace  = kubernetes_namespace.coder.metadata[0].name
  repository = "oci://ghcr.io/coder/chart"
  chart      = "coder"
  version    = "2.36.7"

  values = [
    yamlencode({
      coder = {
        # CODER_ACCESS_URL is set explicitly below.
        envUseClusterAccessURL = false

        # The env form of these two flags hits an upstream env-parser bug in
        # 2.36.7 ("parse number: GITHUB_DEFAULT_PROVIDER_ENABLE"), so they are
        # passed as args instead: one kills the default GitHub *external auth*
        # provider (git auth in workspaces), the other the default GitHub
        # *login* provider (the "Sign in with GitHub" button).
        commandArgs = [
          "server",
          "--external-auth-github-default-provider-enable=false",
          "--oauth2-github-default-provider-enable=false",
        ]

        service = {
          type = "ClusterIP"
        }

        # Grant coderd's service account pod/PVC/Deployment permissions in the
        # dedicated coder-workspaces namespace (the chart creates a Role +
        # RoleBinding there, mirroring coder-workspace-perms in this
        # namespace). Referencing the namespace resource here also orders this
        # helm upgrade after its creation.
        serviceAccount = {
          workspaceNamespaces = [
            {
              name = kubernetes_namespace.coder_workspaces.metadata[0].name
            }
          ]
        }

        env = [
          {
            name = "CODER_PG_CONNECTION_URL"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.coder_db_url.metadata[0].name
                key  = "url"
              }
            }
          },
          {
            name  = "CODER_ACCESS_URL"
            value = "https://${local.coder_domain}"
          },
          {
            name  = "CODER_WILDCARD_ACCESS_URL"
            value = local.coder_suffix_wildcard
          },
          # Recommended once subdomain apps are in use: path apps share the
          # dashboard origin and are XSS-able by a malicious workspace.
          {
            name  = "CODER_DISABLE_PATH_APPS"
            value = "true"
          },
          # Host-only (__Host- prefixed) cookies. The suffix wildcard lives one
          # label under the base domain, so without this the app-session cookie
          # would otherwise be scoped to .jd-chapman.dev (all sibling apps).
          {
            name  = "CODER_HOST_PREFIX_COOKIE"
            value = "true"
          },
          # First OIDC login creates the owner account; owners keep password
          # login as a lockout escape hatch.
          {
            name  = "CODER_DISABLE_PASSWORD_AUTH"
            value = "true"
          },
          {
            name  = "CODER_TELEMETRY_ENABLE"
            value = "false"
          },
          # The embedded AI Gateway is Premium-licensed (AI Governance); don't
          # run the in-memory gateway we can't use without a license.
          {
            name  = "CODER_AI_GATEWAY_ENABLED"
            value = "false"
          },
          {
            name  = "CODER_OIDC_ISSUER_URL"
            value = data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url
          },
          {
            name  = "CODER_OIDC_CLIENT_ID"
            value = keycloak_openid_client.coder.client_id
          },
          {
            name = "CODER_OIDC_CLIENT_SECRET"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.coder_oidc.metadata[0].name
                key  = "client-secret"
              }
            }
          },
          # Keycloak emails federated from LDAP are frequently unverified.
          {
            name  = "CODER_OIDC_IGNORE_EMAIL_VERIFIED"
            value = "true"
          },
          {
            name  = "CODER_OIDC_SIGN_IN_TEXT"
            value = "Sign in with Keycloak"
          },
          {
            name  = "CODER_OIDC_ICON_URL"
            value = "https://www.keycloak.org/resources/images/keycloak_icon_512px.svg"
          },
          # Traefik (hostNetwork) and Cloudflare sit in front; trust the CF
          # client IP header and X-Forwarded-Host from the node/LAN ranges.
          {
            name  = "CODER_PROXY_TRUSTED_HEADERS"
            value = "Cf-Connecting-Ip"
          },
          {
            name  = "CODER_PROXY_TRUSTED_ORIGINS"
            value = "10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
          },
          {
            name  = "CODER_PROMETHEUS_ENABLE"
            value = "true"
          },
          # Native OTel (Go SDK): no Instrumentation CR needed.
          {
            name  = "CODER_TRACE_ENABLE"
            value = "true"
          },
          {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = local.otel_endpoint
          },
          {
            name  = "OTEL_EXPORTER_OTLP_PROTOCOL"
            value = "http/protobuf"
          },
          {
            name  = "OTEL_SERVICE_NAME"
            value = "coder"
          },
        ]

        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }

          limits = {
            cpu    = "1"
            memory = "2Gi"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_manifest.coder_db,
    kubernetes_secret.coder_db_url,
    kubernetes_secret.coder_oidc,
    keycloak_openid_client.coder,
  ]
}
