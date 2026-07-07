resource "kubernetes_config_map" "configure_erpnext_script" {
  metadata {
    name      = "configure-erpnext-script"
    namespace = kubernetes_namespace.erpnext.metadata[0].name
  }

  data = {
    "configure_erpnext.py" = <<-EOT
      import frappe
      import os

      def install_presets():
          country = "United Kingdom"
          from erpnext.setup.setup_wizard.operations import install_fixtures
          from frappe.desk.page.setup_wizard.setup_wizard import make_records

          try:
              install_fixtures.install(country)
          except Exception as e:
              print("Warning: install_fixtures.install() failed: " + str(e))
              print("Creating preset records manually (skipping supplier scorecard)...")
              records = install_fixtures.get_preset_records(country)
              make_records(records)

      def clear_stale_locks():
          import glob
          locks_dir = os.path.join(frappe.local.site_path, "locks")
          if os.path.isdir(locks_dir):
              for lock_file in glob.glob(os.path.join(locks_dir, "*.lock")):
                  os.remove(lock_file)
                  print("Removed stale lock: " + os.path.basename(lock_file))

      def configure():
          company_name = "JDC Projects"

          # Clear stale file locks from previous failed attempts.
          # Frappe's queue_action() creates file locks on the PVC that persist
          # across pod restarts. If a previous attempt failed after locking a
          # document, the lock prevents retries with DocumentLockedError.
          clear_stale_locks()

          # --- Company setup ---
          # We create the company manually instead of using ERPNext's setup_complete()
          # because setup_complete() calls stage_fixtures() which imports
          # frappe.core.doctype.supplier_scorecard_variable — a doctype removed
          # from Frappe core. This is a bug in ERPNext v16.26.2 (latest v16 as of
          # Jul 2026). See recent refactoring activity:
          # https://github.com/frappe/erpnext/pull/55168
          # https://github.com/frappe/erpnext/issues?q=supplier_scorecard_variable
          #
          # When this is fixed, replace this manual company creation with:
          #   from erpnext.setup.setup_wizard.setup_wizard import setup_complete
          #   setup_complete({
          #       "company_name": company_name,
          #       "country": "United Kingdom",
          #       "currency": "GBP",
          #       "fiscal_year_start_date": "2026-04-06",
          #       "language": "en-GB",
          #   })
          if not frappe.db.exists("Company", company_name):
              # Install preset fixtures (Warehouse Types, Item Groups, etc.)
              # before creating the Company. Only runs on first setup, not on
              # retries — avoids NestedSet errors from re-inserting existing
              # records with stale NSM left/right values.
              install_presets()

              print("Creating company: " + company_name)
              company = frappe.get_doc({
                  "doctype": "Company",
                  "company_name": company_name,
                  "abbr": "JDC",
                  "country": "United Kingdom",
                  "default_currency": "GBP",
                  "create_chart_of_accounts_based_on": "Standard Template",
                  "chart_of_accounts": "Standard",
                  "enable_perpetual_inventory": 1,
              })
              company.insert(ignore_permissions=True)

              # Create fiscal year (UK tax year: April 6 - April 5)
              # Compute the current UK tax year from today's date.
              # If before April 6, the tax year started the previous year.
              from datetime import date
              today = date.today()
              if today.month < 4 or (today.month == 4 and today.day < 6):
                  fy_start_year = today.year - 1
              else:
                  fy_start_year = today.year

              fy = frappe.get_doc({
                  "doctype": "Fiscal Year",
                  "year": f"{fy_start_year}-{fy_start_year + 1}",
                  "year_start_date": f"{fy_start_year}-04-06",
                  "year_end_date": f"{fy_start_year + 1}-04-05",
              })
              fy.insert(ignore_permissions=True)

              # Mark setup as complete to skip the wizard
              frappe.db.set_single_value("System Settings", "setup_complete", 1)
              frappe.db.commit()
              print("Company setup complete")
          else:
              print("Company already exists, skipping setup")

          # --- Block unnecessary modules ---
          # Block Module is a child table of Module Profile — we create a
          # Module Profile with the blocked modules and assign it to all
          # users via the OIDC group_module_mappings.
          blocked_modules = [
              "Stock",
              "Manufacturing",
              "Subcontracting",
              "Quality Management",
              "EDI",
              "Telephony",
              "ERPNext Integrations",
              "Regional",
              "Geo",
              "Maintenance",
              "Portal",
              "Bulk Transaction",
              "Website",
              "Utilities",
          ]

          mp_name = "Default"
          existing_mp = frappe.db.exists("Module Profile", mp_name)
          if existing_mp:
              mp = frappe.get_doc("Module Profile", existing_mp)
          else:
              mp = frappe.new_doc("Module Profile")
              mp.module_profile_name = mp_name

          mp.block_modules = []
          for module in blocked_modules:
              mp.append("block_modules", {"module": module})

          if existing_mp:
              mp.save(ignore_permissions=True)
          else:
              mp.insert(ignore_permissions=True)

          frappe.db.commit()
          print(f"Module Profile '{mp_name}' created with {len(blocked_modules)} blocked modules")

          # --- Create Role Profiles ---
          # System Manager alone is NOT a superuser in Frappe — many doctypes
          # (Sales Invoice, Website Theme, Work Order, etc.) only grant
          # permissions to specific roles (Accounts Manager, Website Manager,
          # Manufacturing User), not System Manager. We include all Manager
          # roles so app_admins users have full module access.
          #
          # Additionally, we add System Manager to DocPerm for ALL doctypes
          # below (see ensure_system_manager_permissions), which gives System
          # Manager true admin-level access to every doctype.
          #
          # The Administrator role is NOT included because Frappe's get_roles()
          # filters it out for non-Administrator users — it only works on the
          # Administrator USER, not on regular SSO users.
          manager_roles = [
              "System Manager",
              "Accounts Manager",
              "Sales Manager",
              "Sales Master Manager",
              "Purchase Manager",
              "Purchase Master Manager",
              "Stock Manager",
              "Item Manager",
              "Website Manager",
              "Projects Manager",
              "HR Manager",
              "Manufacturing Manager",
              "Maintenance Manager",
              "Quality Manager",
              "Fleet Manager",
              "Delivery Manager",
              "Marketing Manager",
              "Newsletter Manager",
              "Dashboard Manager",
              "Report Manager",
              "Script Manager",
              "Workspace Manager",
          ]

          role_profiles = {
              "ERPNext Admin": manager_roles,
              "ERPNext User": ["Accounts User", "Sales User", "Purchase User"],
          }

          for profile_name, roles in role_profiles.items():
              existing = frappe.db.exists("Role Profile", profile_name)
              if existing:
                  doc = frappe.get_doc("Role Profile", existing)
                  print("Updating Role Profile: " + profile_name)
              else:
                  doc = frappe.new_doc("Role Profile")
                  print("Creating Role Profile: " + profile_name)

              # The Role Profile doctype uses "role_profile" as its name field
              # (autoname: role_profile), not "name".
              doc.role_profile = profile_name

              doc.roles = []
              for role in roles:
                  doc.append("roles", {"role": role})

              if existing:
                  doc.save(ignore_permissions=True)
              else:
                  doc.insert(ignore_permissions=True)

          # --- Configure Social Login Key ---
          client_id = os.environ["KEYCLOAK_CLIENT_ID"]
          client_secret = os.environ["KEYCLOAK_CLIENT_SECRET"]
          base_url = os.environ["KEYCLOAK_BASE_URL"]
          userinfo_url = os.environ["KEYCLOAK_USERINFO_URL"]

          existing = frappe.db.exists("Social Login Key", "keycloak")
          if existing:
              doc = frappe.get_doc("Social Login Key", existing)
              print("Updating Social Login Key: keycloak")
          else:
              doc = frappe.new_doc("Social Login Key")
              doc.name = "keycloak"
              print("Creating Social Login Key: keycloak")

          doc.update({
              "provider_name": "Keycloak",
              "social_login_provider": "Custom",
              "client_id": client_id,
              "client_secret": client_secret,
              "base_url": base_url,
              "authorize_url": "/protocol/openid-connect/auth",
              "access_token_url": "/protocol/openid-connect/token",
              "redirect_url": "/api/method/oidc_extended.callback.custom/keycloak",
              "api_endpoint": userinfo_url,
              "custom_base_url": 1,
              "auth_url_data": '{"response_type": "code", "scope": "openid profile email"}',
              "user_id_property": "preferred_username",
              "sign_ups": "Allow",
              "enable_social_login": 1,
          })

          if existing:
              doc.save(ignore_permissions=True)
          else:
              doc.insert(ignore_permissions=True)

          # --- Configure OIDC Extended Configuration ---
          existing = frappe.db.exists("OIDC Extended Configuration", "keycloak")
          if existing:
              doc = frappe.get_doc("OIDC Extended Configuration", existing)
              print("Updating OIDC Extended Configuration: keycloak")
          else:
              doc = frappe.new_doc("OIDC Extended Configuration")
              print("Creating OIDC Extended Configuration: keycloak")

          # The doctype uses autoname: format:{provider}, so the document name
          # is derived from the provider field. Setting doc.name directly is
          # silently overridden.
          doc.provider = "keycloak"

          doc.groups_claim_name = "groups"
          doc.given_name_claim_name = "given_name"
          doc.family_name_claim_name = "family_name"
          doc.email_claim_name = "email"

          doc.group_role_mappings = []
          doc.append("group_role_mappings", {"group": "app_admins", "role_profile": "ERPNext Admin"})
          doc.append("group_role_mappings", {"group": "system_admins", "role_profile": "ERPNext Admin"})
          doc.append("group_role_mappings", {"group": "app_users", "role_profile": "ERPNext User"})

          doc.fallback_role_profiles = []

          doc.group_module_mappings = []
          doc.fallback_module_profile = "Default"

          if existing:
              doc.save(ignore_permissions=True)
          else:
              doc.insert(ignore_permissions=True)

          # --- Mark installed apps as setup complete ---
          # frappe.is_setup_complete() checks the Installed Application doctype's
          # is_setup_complete field, NOT System Settings.setup_complete. This is
          # normally set by setup_complete() in the setup wizard, which we bypassed
          # due to the supplier_scorecard_variable bug. Without this, the desk
          # redirects to /desk/setup-wizard on every login.
          for app in frappe.get_all("Installed Application", pluck="name"):
              frappe.db.set_value("Installed Application", app, "is_setup_complete", 1)

          # Set the desk home page to "home" instead of "setup-wizard".
          # The setup wizard sets desktop:home_page to "setup-wizard" during
          # site creation, and normally changes it to "home" in setup_complete().
          # Since we bypassed setup_complete(), we must do this manually.
          frappe.db.set_default("desktop:home_page", "home")

          frappe.db.commit()
          print("Installed apps marked as setup complete")

          # --- Ensure System Manager has full permissions on all doctypes ---
          # Many ERPNext doctypes (Work Order, Sales Invoice, Website Theme,
          # etc.) don't include System Manager in their DocPerm entries — they
          # only grant permissions to specific roles (Manufacturing User,
          # Accounts Manager, Website Manager). This makes it impossible for
          # System Manager users to access these doctypes.
          #
          # The Administrator USER bypasses all permission checks, but regular
          # SSO users can't be the Administrator user. The Administrator ROLE
          # is filtered out by get_roles() for non-Administrator users.
          #
          # We add System Manager with full permissions to all doctypes that
          # don't already have it. This is idempotent — it only adds missing
          # entries, never modifies or removes existing ones.
          doctypes_without_sm = frappe.db.sql("""
              SELECT DISTINCT dt.name FROM tabDocType dt
              WHERE dt.istable = 0 AND dt.issingle = 0
              AND NOT EXISTS (
                  SELECT 1 FROM tabDocPerm dp
                  WHERE dp.parent = dt.name AND dp.role = 'System Manager'
              )
          """, as_list=True)

          for [dt] in doctypes_without_sm:
              perm = frappe.get_doc({
                  "doctype": "DocPerm",
                  "parent": dt,
                  "parenttype": "DocType",
                  "parentfield": "permissions",
                  "role": "System Manager",
                  "read": 1,
                  "write": 1,
                  "create": 1,
                  "delete": 1,
                  "select": 1,
                  "permlevel": 0,
                  "if_owner": 0,
              })
              perm.flags.ignore_permissions = True
              perm.flags.ignore_mandatory = True
              perm.db_insert()

          frappe.db.commit()
          print(f"System Manager permissions added to {len(doctypes_without_sm)} doctypes")

          # --- Lockdown settings ---
          frappe.db.set_single_value("System Settings", "disable_user_pass_login", 1)
          frappe.db.set_single_value("System Settings", "enable_scheduler", 1)
          frappe.db.set_single_value("System Settings", "login_with_email_link", 0)
          frappe.db.set_single_value("Website Settings", "disable_signup", 1)

          # --- Create Server Script to suppress password prompt ---
          # The frappe-oidc-extended plugin creates users with a random password.
          # Frappe prompts new users to set their own password on first login.
          # Since password login is disabled, the password is irrelevant.
          # This Server Script sets last_password_reset_date on user creation
          # to suppress the prompt. Requires server_script_enabled in common_site_config.
          if frappe.db.exists("DocType", "Server Script"):
              import json
              config_path = os.path.join(frappe.local.sites_path, "common_site_config.json")
              with open(config_path) as f:
                  config = json.load(f)
              if not config.get("server_script_enabled"):
                  config["server_script_enabled"] = 1
                  with open(config_path, "w") as f:
                      json.dump(config, f, indent=1, sort_keys=True)
                  frappe.clear_cache()
                  print("Server Scripts enabled in common_site_config.json")

              script_name = "suppress_password_prompt"
              if not frappe.db.exists("Server Script", script_name):
                  ss = frappe.new_doc("Server Script")
                  ss.name = script_name
                  ss.script_type = "DocType Event"
                  ss.reference_doctype = "User"
                  ss.doctype_event = "Before Insert"
                  ss.script = 'doc.last_password_reset_date = "2000-01-01"'
                  ss.disabled = 0
                  ss.insert(ignore_permissions=True)
                  frappe.db.commit()
                  print("Server Script created: " + script_name)
              else:
                  print("Server Script already exists: " + script_name)
          else:
              print("Warning: Server Script doctype not found, cannot suppress password prompt")

          frappe.db.commit()

          print("ERPNext configuration complete")

      if __name__ == "__main__":
          site_name = os.environ["SITE_NAME"]
          site_path = os.path.join("/home/frappe/frappe-bench/sites", site_name)
          if not os.path.exists(site_path):
              print("Site directory does not exist yet: " + site_path)
              import sys
              sys.exit(1)

          frappe.init(site=site_name, sites_path="sites")
          frappe.connect()
          configure()
    EOT

    "configure_erpnext.sh" = <<-EOT
      #!/bin/bash

      cd /home/frappe/frappe-bench

      for i in $(seq 1 5); do
          echo "Attempting ERPNext configuration (attempt $i)..."

          bench --site "$SITE_NAME" list-apps 2>/dev/null | grep -q oidc_extended || \
              bench --site "$SITE_NAME" install-app oidc_extended 2>&1 || true

          if ./env/bin/python /scripts/configure_erpnext.py 2>&1; then
              echo "ERPNext configuration succeeded"
              exit 0
          fi
          echo "Attempt failed, retrying in 5s..."
          sleep 5
      done

      echo "ERPNext configuration failed after 5 attempts"
      exit 1
    EOT
  }
}

resource "null_resource" "configure_erpnext_trigger" {
  triggers = {
    script_hash = sha256(jsonencode(kubernetes_config_map.configure_erpnext_script.data))
  }
}

resource "kubernetes_job" "configure_erpnext" {
  metadata {
    name      = "configure-erpnext"
    namespace = kubernetes_namespace.erpnext.metadata[0].name
  }

  spec {
    backoff_limit           = 0
    active_deadline_seconds = 900

    template {
      metadata {
        name = "configure-erpnext"
      }

      spec {
        restart_policy = "Never"

        security_context {
          supplemental_groups = [1000]
        }

        container {
          name  = "configure-erpnext"
          image = "${local.erpnext_image_repo}:${local.erpnext_image_tag}"

          command = ["/bin/bash", "/scripts/configure_erpnext.sh"]

          env {
            name  = "SITE_NAME"
            value = local.erpnext_domain
          }

          env {
            name  = "KEYCLOAK_CLIENT_ID"
            value = keycloak_openid_client.erpnext.client_id
          }

          env {
            name = "KEYCLOAK_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_client_secret.metadata[0].name
                key  = "client-secret"
              }
            }
          }

          env {
            name  = "KEYCLOAK_BASE_URL"
            value = data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url
          }

          env {
            name  = "KEYCLOAK_USERINFO_URL"
            value = data.terraform_remote_state.keycloak.outputs.keycloak_api_url
          }

          env {
            name  = "SITE_URL"
            value = "https://${local.erpnext_domain}"
          }

          env {
            name  = "FRAPPE_STREAM_LOGGING"
            value = "1"
          }

          volume_mount {
            name       = "sites"
            mount_path = "/home/frappe/frappe-bench/sites"
          }

          volume_mount {
            name       = "scripts"
            mount_path = "/scripts"
          }
        }

        volume {
          name = "sites"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.erpnext_sites.metadata[0].name
          }
        }

        volume {
          name = "scripts"
          config_map {
            name = kubernetes_config_map.configure_erpnext_script.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.configure_erpnext_trigger,
      kubernetes_secret.keycloak_client_secret,
    ]
  }

  timeouts {
    create = "20m"
  }

  depends_on = [
    helm_release.erpnext,
    module.erpnext_ingress,
  ]
}
