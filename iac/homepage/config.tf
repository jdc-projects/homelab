resource "kubernetes_config_map" "homepage_config_yamls" {
  metadata {
    name      = "homepage-config-yamls"
    namespace = kubernetes_namespace.homepage.metadata[0].name
  }

  data = {
    "settings.yaml"   = <<-EOF
      # https://gethomepage.dev/configs/settings/
      title: ${var.server_base_domain} apps
      description: Apps and services on ${var.server_base_domain}
      # startUrl: PLACEHOLDER
      # background:
        # image: https://images.unsplash.com/photo-1502790671504-542ad42d5189?auto=format&fit=crop&w=2560&q=80 or /images/background.png
        # blur: sm
        # saturate: 50
        # brightness: 50
        # opacity: 50
      # cardBlur: sm
      # favicon: https://www.google.com/favicon.ico or ./favicon (path relative to /app/public)
      theme: dark
      color: slate
      # layout: https://gethomepage.dev/configs/settings/#layout
      headerStyle: underlined
      # base: PLACEHOLDER
      language: en-gb
      # target: _blank
      providers:
      # openweathermap: openweathermapapikey
      # finnhub: yourfinnhubapikeyhere
      # longhorn:
        # url: https://longhorn.example.com
        # username: admin
        # password: LonghornPassword
      # quicklaunch:
        # searchDescriptions: true
        # hideInternetSearch: true
        # showSearchSuggestions: true
        # hideVisitURL: true
        # provider: google
      hideVersion: true
      showStats: false
      statusStyle: dot
      # instanceName: homepage # *****
      hideErrors: false
    EOF
    "bookmarks.yaml"  = <<-EOF
    EOF
    "widgets.yaml"    = <<-EOF
    EOF
    "services.yaml"   = <<-EOF
    EOF
    "kubernetes.yaml" = <<-EOF
      mode: disabled
    EOF
    "docker.yaml"     = <<-EOF
    EOF
    "custom.css"      = <<-EOF
    EOF
    "custom.js"       = <<-EOF
    EOF
  }
}
