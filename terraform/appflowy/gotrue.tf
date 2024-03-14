# config options: https://github.com/supabase/gotrue/blob/master/example.env

# ***** all config options *****

resource "kubernetes_config_map" "gotrue_env" {
  metadata {
    name      = "gotrue-env"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  data = {
    GOTRUE_JWT_EXP                = "3600"
    GOTRUE_JWT_AUD                = "authenticated"
    GOTRUE_JWT_DEFAULT_GROUP_NAME = "authenticated"
    GOTRUE_JWT_ADMIN_ROLES        = "supabase_admin,service_role"

    GOTRUE_DB_DRIVER = "postgres"
    DB_NAMESPACE     = "auth"
    API_EXTERNAL_URL = "http://localhost:${local.gotrue_port}"
    GOTRUE_API_HOST  = "localhost"
    PORT             = local.gotrue_port

    GOTRUE_SMTP_HOST          = var.smtp_host
    GOTRUE_SMTP_PORT          = var.smtp_port
    GOTRUE_SMTP_USER          = var.smtp_username
    GOTRUE_SMTP_MAX_FREQUENCY = "5s"
    GOTRUE_SMTP_ADMIN_EMAIL   = "noreply@${var.server_base_domain}"
    GOTRUE_SMTP_SENDER_NAME   = "Appflowy"

    GOTRUE_MAILER_AUTOCONFIRM                 = "true"
    GOTRUE_MAILER_URLPATHS_CONFIRMATION       = "/verify"
    GOTRUE_MAILER_URLPATHS_INVITE             = "/verify"
    GOTRUE_MAILER_URLPATHS_RECOVERY           = "/verify"
    GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE       = "/verify"
    GOTRUE_MAILER_SUBJECTS_CONFIRMATION       = "Confirm Your Email"
    GOTRUE_MAILER_SUBJECTS_RECOVERY           = "Reset Your Password"
    GOTRUE_MAILER_SUBJECTS_MAGIC_LINK         = "Your Magic Link"
    GOTRUE_MAILER_SUBJECTS_EMAIL_CHANGE       = "Confirm Email Change"
    GOTRUE_MAILER_SUBJECTS_INVITE             = "You have been invited"
    GOTRUE_MAILER_SECURE_EMAIL_CHANGE_ENABLED = "true"

    GOTRUE_MAILER_TEMPLATES_INVITE       = ""
    GOTRUE_MAILER_TEMPLATES_CONFIRMATION = ""
    GOTRUE_MAILER_TEMPLATES_RECOVERY     = ""
    GOTRUE_MAILER_TEMPLATES_MAGIC_LINK   = ""
    GOTRUE_MAILER_TEMPLATES_EMAIL_CHANGE = ""

    GOTRUE_DISABLE_SIGNUP         = "true"
    GOTRUE_SITE_URL               = "appflowy-flutter://" # "https://${local.appflowy_domain}/"
    GOTRUE_EXTERNAL_EMAIL_ENABLED = "true"
    GOTRUE_EXTERNAL_PHONE_ENABLED = "false"
    GOTRUE_EXTERNAL_IOS_BUNDLE_ID = "com.supabase.auth"

    GOTRUE_URI_ALLOW_LIST = "*"

    GOTRUE_EXTERNAL_APPLE_ENABLED     = "false"
    GOTRUE_EXTERNAL_AZURE_ENABLED     = "false"
    GOTRUE_EXTERNAL_BITBUCKET_ENABLED = "false"
    GOTRUE_EXTERNAL_DISCORD_ENABLED   = "false"
    GOTRUE_EXTERNAL_FACEBOOK_ENABLED  = "false"
    GOTRUE_EXTERNAL_FIGMA_ENABLED     = "false"
    GOTRUE_EXTERNAL_GITLAB_ENABLED    = "false"
    GOTRUE_EXTERNAL_GOOGLE_ENABLED    = "false"
    GOTRUE_EXTERNAL_GITHUB_ENABLED    = "false"
    GOTRUE_EXTERNAL_KAKAO_ENABLED     = "false"
    GOTRUE_EXTERNAL_NOTION_ENABLED    = "false"
    GOTRUE_EXTERNAL_TWITTER_ENABLED   = "false"
    GOTRUE_EXTERNAL_TWITCH_ENABLED    = "false"
    GOTRUE_EXTERNAL_SPOTIFY_ENABLED   = "false"
    GOTRUE_EXTERNAL_LINKEDIN_ENABLED  = "false"
    GOTRUE_EXTERNAL_SLACK_ENABLED     = "false"
    GOTRUE_EXTERNAL_WORKOS_ENABLED    = "false"
    GOTRUE_EXTERNAL_ZOOM_ENABLED      = "false"

    GOTRUE_EXTERNAL_KEYCLOAK_ENABLED      = "true"
    GOTRUE_EXTERNAL_KEYCLOAK_CLIENT_ID    = ""
    GOTRUE_EXTERNAL_KEYCLOAK_REDIRECT_URI = "https://${local.appflowy_domain}/auth/v1/callback"
    GOTRUE_EXTERNAL_KEYCLOAK_URL          = "" # e.g. "http://172.17.0.1:8080/auth/realms/SupaBase"

    GOTRUE_EXTERNAL_FLOW_STATE_EXPIRY_DURATION = "300s"

    GOTRUE_SMS_AUTOCONFIRM                = "false"
    GOTRUE_SMS_MAX_FREQUENCY              = "5s"
    GOTRUE_SMS_OTP_EXP                    = "6000"
    GOTRUE_SMS_OTP_LENGTH                 = "6"
    GOTRUE_SMS_PROVIDER                   = "twilio"
    GOTRUE_SMS_TWILIO_ACCOUNT_SID         = ""
    GOTRUE_SMS_TWILIO_AUTH_TOKEN          = ""
    GOTRUE_SMS_TWILIO_MESSAGE_SERVICE_SID = ""
    GOTRUE_SMS_TEMPLATE                   = "This is from supabase. Your code is {{ .Code }} ."
    GOTRUE_SMS_MESSAGEBIRD_ACCESS_KEY     = ""
    GOTRUE_SMS_MESSAGEBIRD_ORIGINATOR     = ""
    GOTRUE_SMS_TEXTLOCAL_API_KEY          = ""
    GOTRUE_SMS_TEXTLOCAL_SENDER           = ""
    GOTRUE_SMS_VONAGE_API_KEY             = ""
    GOTRUE_SMS_VONAGE_API_SECRET          = ""
    GOTRUE_SMS_VONAGE_FROM                = ""

    GOTRUE_SECURITY_CAPTCHA_ENABLED  = "false"
    GOTRUE_SECURITY_CAPTCHA_PROVIDER = "hcaptcha"
    GOTRUE_SECURITY_CAPTCHA_SECRET   = "0x0000000000000000000000000000000000000000"
    GOTRUE_SECURITY_CAPTCHA_TIMEOUT  = "10s"
    GOTRUE_SESSION_KEY               = ""

    GOTRUE_EXTERNAL_SAML_ENABLED      = "false"
    GOTRUE_EXTERNAL_SAML_METADATA_URL = ""
    GOTRUE_EXTERNAL_SAML_API_BASE     = "http://localhost:${local.gotrue_port}"
    GOTRUE_EXTERNAL_SAML_NAME         = "auth0"
    GOTRUE_EXTERNAL_SAML_SIGNING_CERT = ""
    GOTRUE_EXTERNAL_SAML_SIGNING_KEY  = ""

    GOTRUE_LOG_LEVEL                                         = "info"
    GOTRUE_SECURITY_REFRESH_TOKEN_ROTATION_ENABLED           = "false"
    GOTRUE_SECURITY_REFRESH_TOKEN_REUSE_INTERVAL             = "0"
    GOTRUE_SECURITY_UPDATE_PASSWORD_REQUIRE_REAUTHENTICATION = "false"
    GOTRUE_OPERATOR_TOKEN                                    = "unused-operator-token"
    GOTRUE_RATE_LIMIT_HEADER                                 = "X-Forwarded-For"
    GOTRUE_RATE_LIMIT_EMAIL_SENT                             = "100"

    GOTRUE_COOKIE_KEY           = "sb"
    GOTRUE_COOKIE_DOMAIN        = local.appflowy_domain
    GOTRUE_MAX_VERIFIED_FACTORS = 10

    GOTRUE_HOOK_CUSTOM_ACCESS_TOKEN_ENABLED = false
    GOTRUE_HOOK_CUSTOM_ACCESS_TOKEN_URI     = ""
    GOTRUE_HOOK_CUSTOM_ACCESS_TOKEN_SECRET  = ""

    GOTRUE_HOOK_CUSTOM_SMS_PROVIDER_ENABLED = false
    GOTRUE_HOOK_CUSTOM_SMS_PROVIDER_URI     = ""
    GOTRUE_HOOK_CUSTOM_SMS_PROVIDER_SECRET  = ""

    GOTRUE_SMS_TEST_OTP             = "<phone-1>:<otp-1>, <phone-2>:<otp-2>..."
    GOTRUE_SMS_TEST_OTP_VALID_UNTIL = "<ISO date time>" # (e.g. 2023-09-29T08:14:06Z)
  }
}

resource "kubernetes_secret" "gotrue_env" {
  metadata {
    name      = "gotrue-env"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  data = {
    GOTRUE_JWT_SECRET = ""

    DATABASE_URL = ""

    GOTRUE_SMTP_PASS = var.smtp_password

    GOTRUE_EXTERNAL_KEYCLOAK_SECRET = random_password.keycloak_client_secret.result
  }
}

resource "kubernetes_deployment" "gotrue" {
  metadata {
    name      = "gotrue"
    namespace = kubernetes_namespace.appflowy.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "gotrue"
      }
    }

    template {
      metadata {
        labels = {
          app = "gotrue"
        }
      }

      spec {
        container {
          image = "appflowyinc/gotrue:${local.appflowy_version}"
          name  = "gotrue"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.gotrue_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.gotrue_env.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.gotrue_env,
      kubernetes_secret.gotrue_env,
    ]
  }
}
