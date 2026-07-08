resource "kubernetes_config_map" "configure_erpnext_script" {
  metadata {
    name      = "configure-erpnext-script"
    namespace = kubernetes_namespace.erpnext.metadata[0].name
  }

  data = {
    "configure_erpnext.py" = <<-EOF
      import frappe
      import os
      import json

      BLOCKED_MODULES = ${jsonencode(local.blocked_modules)}


      def upsert_doc(doctype, name, name_field="name", data=None, child_tables=None):
          """Create or update a document by name."""
          existing = frappe.db.exists(doctype, name)
          if existing:
              doc = frappe.get_doc(doctype, existing)
              print(f"Updating {doctype}: {name}")
          else:
              doc = frappe.new_doc(doctype)
              doc.set(name_field, name)
              print(f"Creating {doctype}: {name}")
          if data:
              doc.update(data)
          if child_tables:
              for fieldname, items in child_tables.items():
                  doc.set(fieldname, [])
                  for item in items:
                      doc.append(fieldname, item)
          if existing:
              doc.save(ignore_permissions=True)
          else:
              doc.insert(ignore_permissions=True)
          return doc


      def clear_stale_locks():
          import glob
          locks_dir = os.path.join(frappe.local.site_path, "locks")
          if os.path.isdir(locks_dir):
              for lock_file in glob.glob(os.path.join(locks_dir, "*.lock")):
                  os.remove(lock_file)
                  print("Removed stale lock: " + os.path.basename(lock_file))


      def run_setup_complete():
          if frappe.db.exists("Company", "${var.company_name}"):
              print("Company already exists, skipping setup")
              return

          from datetime import date
          today = date.today()
          if today.month < 4 or (today.month == 4 and today.day < 6):
              fy_start_year = today.year - 1
          else:
              fy_start_year = today.year

          from erpnext.setup.setup_wizard.setup_wizard import setup_complete
          setup_complete(frappe._dict({
              "company_name": "${var.company_name}",
              "company_abbr": "${var.company_abbr}",
              "country": "${var.country}",
              "currency": "${var.currency}",
              "fy_start_date": f"{fy_start_year}-04-06",
              "fy_end_date": f"{fy_start_year + 1}-04-05",
              "chart_of_accounts": "Standard",
              "language": "en-GB",
          }))
          print("Setup complete finished")


      def mark_setup_complete():
          for app in frappe.get_all("Installed Application", pluck="name"):
              frappe.db.set_value("Installed Application", app, "is_setup_complete", 1)
          frappe.db.set_default("desktop:home_page", "home")
          frappe.db.set_single_value("System Settings", "setup_complete", 1)
          frappe.db.set_single_value("System Settings", "enable_scheduler", 1)
          frappe.db.commit()
          print("Installed apps marked as setup complete")


      def _clear_workspace_sidebar(module):
          """Clear items on Workspace Sidebar records for a module (by name AND module field)."""
          ws_names = set()
          by_name = frappe.db.get_value("Workspace Sidebar", {"name": module, "for_user": None}, "name")
          if by_name:
              ws_names.add(by_name)
          for ws_name in frappe.get_all("Workspace Sidebar", filters={"module": module, "for_user": None}, pluck="name"):
              ws_names.add(ws_name)
          if ws_names:
              for ws_name in ws_names:
                  ws = frappe.get_doc("Workspace Sidebar", ws_name)
                  ws.items = []
                  ws.save(ignore_permissions=True)
          else:
              ws = frappe.new_doc("Workspace Sidebar")
              ws.title = module
              ws.module = module
              ws.items = []
              ws.insert(ignore_permissions=True)


      def block_modules():
          # 1. Module Profile — blocks modules in get_workspaces() DB query filter
          upsert_doc("Module Profile", "Default", name_field="module_profile_name",
              child_tables={"block_modules": [{"module": m} for m in BLOCKED_MODULES]})

          # 2. Workspace Sidebar — clear items so they're filtered from the desk sidebar
          for module in BLOCKED_MODULES:
              _clear_workspace_sidebar(module)

          # 3. Dashboards — no is_hidden field, deletion is the only option
          for module in BLOCKED_MODULES:
              frappe.db.delete("Dashboard", {"module": module})

          # 4. Desktop Icons — set hidden flag (client-side visibility filter)
          blocked_lower = {m.lower() for m in BLOCKED_MODULES}
          ws_module_map = {ws.name.lower(): ws.module or "" for ws in frappe.get_all("Workspace Sidebar", fields=["name", "module"])}
          for icon in frappe.get_all("Desktop Icon", filters={"link_type": "Workspace Sidebar"}, fields=["name", "label"]):
              label_lower = (icon.label or "").lower()
              ws_module = ws_module_map.get(label_lower, "")
              should_hide = label_lower in blocked_lower or ws_module in BLOCKED_MODULES
              frappe.db.set_value("Desktop Icon", icon.name, "hidden", 1 if should_hide else 0, update_modified=False)

          frappe.db.commit()
          print(f"Blocked {len(BLOCKED_MODULES)} modules")


      def create_role_profiles():
          manager_roles = [
              r for r in frappe.get_all("Role", filters={"disabled": 0}, pluck="name")
              if "Manager" in r and r not in ("Administrator", "Workspace Manager")
          ]
          for profile_name, roles in {
              "ERPNext Admin": manager_roles,
              "ERPNext User": ["Accounts User", "Sales User", "Purchase User"],
          }.items():
              upsert_doc("Role Profile", profile_name, name_field="role_profile",
                  child_tables={"roles": [{"role": r} for r in roles]})


      def configure_oidc():
          client_secret = os.environ["KEYCLOAK_CLIENT_SECRET"]

          upsert_doc("Social Login Key", "keycloak", data={
              "provider_name": "Keycloak",
              "social_login_provider": "Custom",
              "client_id": "${keycloak_openid_client.erpnext.client_id}",
              "client_secret": client_secret,
              "base_url": "${data.terraform_remote_state.keycloak.outputs.keycloak_issuer_url}",
              "authorize_url": "/protocol/openid-connect/auth",
              "access_token_url": "/protocol/openid-connect/token",
              "redirect_url": "/api/method/oidc_extended.callback.custom/keycloak",
              "api_endpoint": "${data.terraform_remote_state.keycloak.outputs.keycloak_api_url}",
              "custom_base_url": 1,
              "auth_url_data": '{"response_type": "code", "scope": "openid profile email"}',
              "user_id_property": "preferred_username",
              "sign_ups": "Allow",
              "enable_social_login": 1,
          })

          upsert_doc("OIDC Extended Configuration", "keycloak", name_field="provider", data={
              "groups_claim_name": "groups",
              "given_name_claim_name": "given_name",
              "family_name_claim_name": "family_name",
              "email_claim_name": "email",
              "fallback_role_profiles": [],
              "group_module_mappings": [],
              "fallback_module_profile": "Default",
          }, child_tables={
              "group_role_mappings": [
                  {"group": "app_admins", "role_profile": "ERPNext Admin"},
                  {"group": "system_admins", "role_profile": "ERPNext Admin"},
                  {"group": "app_users", "role_profile": "ERPNext User"},
              ],
          })


      def ensure_system_manager_permissions():
          doctypes = frappe.db.sql("""
              SELECT DISTINCT dt.name FROM tabDocType dt
              WHERE dt.istable = 0 AND dt.issingle = 0
              AND NOT EXISTS (
                  SELECT 1 FROM tabDocPerm dp
                  WHERE dp.parent = dt.name AND dp.role = 'System Manager'
              )
          """, as_list=True)
          for [dt] in doctypes:
              perm = frappe.get_doc({
                  "doctype": "DocPerm",
                  "parent": dt,
                  "parenttype": "DocType",
                  "parentfield": "permissions",
                  "role": "System Manager",
                  "read": 1, "write": 1, "create": 1, "delete": 1, "select": 1,
                  "permlevel": 0, "if_owner": 0,
              })
              perm.flags.ignore_permissions = True
              perm.flags.ignore_mandatory = True
              perm.db_insert()
          frappe.db.commit()
          print(f"System Manager permissions added to {len(doctypes)} doctypes")


      def create_server_script():
          if not frappe.db.exists("DocType", "Server Script"):
              print("Warning: Server Script doctype not found")
              return

          config_path = os.path.join(frappe.local.sites_path, "common_site_config.json")
          with open(config_path) as f:
              config = json.load(f)
          if not config.get("server_script_enabled"):
              config["server_script_enabled"] = 1
              with open(config_path, "w") as f:
                  json.dump(config, f, indent=1, sort_keys=True)
              frappe.clear_cache()
              print("Server Scripts enabled")

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


      def apply_lockdown_settings():
          settings = {
              "System Settings": {
                  "disable_user_pass_login": 1,
                  "login_with_email_link": 0,
              },
              "Website Settings": {
                  "disable_signup": 1,
              },
          }
          for doctype, values in settings.items():
              for field, value in values.items():
                  frappe.db.set_single_value(doctype, field, value)
          frappe.db.commit()
          print("Lockdown settings applied")


      def configure():
          clear_stale_locks()
          run_setup_complete()
          mark_setup_complete()
          block_modules()
          create_role_profiles()
          configure_oidc()
          ensure_system_manager_permissions()
          create_server_script()
          apply_lockdown_settings()
          print("ERPNext configuration complete")


      if __name__ == "__main__":
          frappe.init(site="${local.erpnext_domain}")
          frappe.connect()
          configure()
    EOF

    "configure_erpnext.sh" = <<-EOF
      #!/bin/bash
      cd /home/frappe/frappe-bench/sites

      for i in $(seq 1 3); do
          echo "Attempting ERPNext configuration (attempt $i)..."

          bench --site "${local.erpnext_domain}" list-apps 2>/dev/null | grep -q oidc_extended || \
              bench --site "${local.erpnext_domain}" install-app oidc_extended 2>&1 || true

          if ../env/bin/python /scripts/configure_erpnext.py 2>&1; then
              echo "ERPNext configuration succeeded"
              exit 0
          fi
          echo "Attempt failed, retrying in 5s..."
          sleep 5
      done

      echo "ERPNext configuration failed after 3 attempts"
      exit 1
    EOF
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
            name = "KEYCLOAK_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_client_secret.metadata[0].name
                key  = "client-secret"
              }
            }
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
