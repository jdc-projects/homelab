---
display_name: Default (Kubernetes)
description: Kubernetes pod workspaces on the homelab k3s cluster
icon: /emojis/1f433.png
---

# Default (Kubernetes)

Remote development in Kubernetes pods, provisioned by Coder's embedded
provisioners against the homelab k3s cluster.

## What you get

- A pod (Deployment) running the workspace image — default
  `codercom/example-base:ubuntu` (minimal; an admin can swap the template's
  `image` variable for more preinstalled tooling) — with the Coder agent
  injected.
- A persistent home directory (`/home/coder`) on a ZFS-backed PVC that
  survives workspace restarts.
- code-server (VS Code in the browser), served on a workspace subdomain.

Everything outside `/home/coder` is rebuilt from the image on restart: bake
tools into the image, or manage them via [dotfiles](https://coder.com/docs/dotfiles).

Workspaces auto-stop after 8 hours of inactivity; restart them from the
dashboard or with an autostart schedule.
