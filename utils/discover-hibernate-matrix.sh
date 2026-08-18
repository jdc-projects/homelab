#!/usr/bin/env bash
set -euo pipefail

# Discover the hibernation matrix for one CRD and emit it as a GitHub Actions
# output ("name=[{...}, {...}]").
#
# Usage: discover-hibernate-matrix.sh <resource> <yq-projection> <output-name>
#   resource     - plural[.group] as accepted by `kubectl get` (e.g.
#                  clusters.postgresql.cnpg.io, kafkas.kafka.strimzi.io)
#   projection   - yq expression applied to each .items[] element; must emit
#                  a JSON object (use -o json -I 0 style-friendly syntax)
#   output-name  - key written to $GITHUB_OUTPUT (e.g. databases, clusters)
#
# CRs in namespaces labeled velero.io/exclude-from-backup=true are dropped:
# hibernating workloads velero never snapshots is pointless churn. When no
# namespace carries the label, nothing is excluded. An empty result emits an
# empty value ("name=") so downstream `if: outputs.name != ''` gates skip.
#
# Local testing: run with KUBECONFIG set and no GITHUB_OUTPUT; the result is
# printed to stdout.

resource="$1"
projection="$2"
output_name="$3"

kubectl get "$resource" -A -o yaml > clusters.yml

EXCLUDED_NS=$(kubectl get ns -l velero.io/exclude-from-backup=true -o jsonpath='{.items[*].metadata.name}' | tr ' ' ',')
# __none__ sentinel: yq's env() errors on an empty/unset variable.
export EXCLUDED_NS="${EXCLUDED_NS:-__none__}"

yq ".items[]
  | .metadata.namespace as \$ns
  | select((env(EXCLUDED_NS) | split(\",\") | map(. == \$ns) | any) | not)
  | $projection" clusters.yml -o json -I 0 > dbs.json

sed -i '{:q;N;s/\n/, /g;t q}' dbs.json
sed -i 's#^#[#' dbs.json
sed -i 's#$#]#' dbs.json
truncate -s -1 dbs.json

echo "$output_name=$(cat dbs.json)" >> "${GITHUB_OUTPUT:-/dev/stdout}"
