#!/usr/bin/env bash
# Pre-deploy check: detect held/stale terraform state locks before deploying.
#
# The terraform kubernetes backend stores each module's state lock as a Lease
# (coordination.k8s.io/v1) named `lock-tfstate-default-<module>` in the
# tf-state namespace. The Lease's holderIdentity field holds the lock UUID
# while a terraform process holds the lock, and is cleared on clean release.
# A non-empty holderIdentity = a held lock — almost always stale, left behind
# by a crashed/killed local `terraform plan`/`apply`. The deploy workflow's
# `terraform apply` will fail to acquire its lock against a stale holder, so
# run this before triggering the deploy workflow.
#
# Usage:   utils/check-tf-locks.sh
# Exit 0 = no held locks (safe to deploy).
# Exit 1 = held/stale locks found (clear them before deploying).
# Exit 2 = could not reach the cluster / list leases.
set -euo pipefail

NS="${TF_STATE_NS:-tf-state}"

if ! raw=$(kubectl get lease -n "$NS" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.holderIdentity}{"\n"}{end}' 2>&1); then
  echo "ERROR: could not list leases in $NS:" >&2
  echo "$raw" >&2
  exit 2
fi

held=$(printf '%s\n' "$raw" | awk -F'\t' '$2 != "" {print}')

if [ -z "$held" ]; then
  echo "No terraform state locks held in $NS."
  exit 0
fi

echo "Held/stale terraform state lock(s) in $NS — clear before deploying:" >&2
while IFS=$'\t' read -r lease holder; do
  [ -z "$holder" ] && continue
  mod="${lease#lock-tfstate-default-}"
  echo "  module=$mod   lock-id=$holder" >&2
  echo "    -> cd terraform/$mod && tofu force-unlock -force $holder" >&2
done <<< "$held"
exit 1
