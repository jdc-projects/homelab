import {
  to = harbor_project.library
  id = "/projects/1"
}

resource "harbor_project" "library" {
  name                   = "library"
  public                 = "false"
  vulnerability_scanning = "false"
  enable_content_trust   = "false"
  force_destroy          = "false"
  cve_allowlist          = []

  lifecycle {
    # if this get's destroyed after import, it's a pain to recover
    prevent_destroy = true
  }
}
