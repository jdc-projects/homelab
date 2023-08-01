import {
  to   = harbor_project.library
  from = "/projects/1"
}

resource "harbor_project" "library" {
  name                   = "library"
  public                 = "false"
  vulnerability_scanning = "false"
  enable_content_trust   = "false"
  force_destroy          = "false"
  cve_allowlist          = []
}
