# elasticsearch-operator

Installs [ECK](https://github.com/elastic/cloud-on-k8s) (Elastic Cloud on
Kubernetes) — Elastic's official operator for Elasticsearch/Kibana/Beats/etc.
on Kubernetes. Cluster-scoped (single operator reconciles `Elasticsearch` CRs
in any namespace), matching how `opensearch-operator` and `kafka-operator`
are wired.

Pinned to **ECK 3.5.0**. See `elasticsearch-operator.tf` for the rationale.

## Consuming from another module

Drop an `Elasticsearch` CR into the consuming app's namespace and point the
app at the resulting `<cr>-es-http` Service. Mirrors how `posthog/opensearch.tf`
consumes the OpenSearch operator.

```hcl
resource "kubernetes_manifest" "elasticsearch" {
  manifest = {
    apiVersion = "elasticsearch.k8s.elastic.co/v1"
    kind       = "Elasticsearch"

    metadata = {
      name      = "elasticsearch"
      namespace = kubernetes_namespace.app.metadata[0].name
    }

    spec = {
      version = "7.17.29"   # see "ES version pinning" below

      nodeSets = [{
        name  = "default"
        count = 1

        config = {
          "node.store.allow_mmap" = "false"
        }

        podTemplate = {
          spec = {
            initContainers = [{
              name    = "install-plugins"
              command = ["/bin/sh", "-c"]
              args    = ["bin/elasticsearch-plugin install --batch ingest-attachment"]
            }]

            containers = [{
              name = "elasticsearch"
              env = [{ name = "ES_JAVA_OPTS", value = "-Xms512m -Xmx512m" }]
              resources = {
                requests = { cpu = "250m", memory = "2Gi" }
                limits   = { cpu = "1",    memory = "2Gi" }
              }
            }]
          }
        }

        volumeClaimTemplates = [{
          metadata = { name = "elasticsearch-data" }
          spec = {
            accessModes      = ["ReadWriteOnce"]
            storageClassName = "openebs-zfs-localpv-bulk"
            resources = { requests = { storage = "10Gi" } }
          }
        }]
      }]
    }
  }

  field_manager { force_conflicts = true }
  computed_fields = ["metadata.labels", "metadata.annotations"]
}
```

The operator creates:
- `Service` `<cr>-es-http`       — the client endpoint (port 9200)
- `Service` `<cr>-es-internal-http` — same, for the operator's own probes
- `Service` `<cr>-es-transport`   — inter-node traffic (port 9300)
- `Secret` `<cr>-es-elastic-user` — the auto-generated `elastic` superuser
  password (key: `elastic`)
- `Secret` `<cr>-es-http-certs-public` — the HTTP CA cert (if TLS is on)
- `StatefulSet` `<cr>-es-default`

## Gotchas learned the hard way

### Auth is mandatory — there is no plaintext-no-auth mode

ECK **always** enables Elasticsearch security: the `elastic` superuser is
created on first boot with a random password written to
`<cr>-es-elastic-user`. Apps that expect Huly's bundled chart posture
(plaintext HTTP, no auth) must instead read that Secret and authenticate.
For the `@elastic/elasticsearch` JS client (what Huly uses), URL-embedded
basic auth works:

```hcl
locals {
  es_password = data.kubernetes_secret.es_elastic_user.data["elastic"]
  es_url      = "https://elastic:${es_password}@elasticsearch-es-http.${kubernetes_namespace.app.metadata[0].name}.svc:9200"
}
```

You can disable HTTP-layer TLS (`spec.http.tls.selfSignedCertificate.disabled: true`)
if you want plaintext transport — auth is still required either way. Disabling
the security module entirely via `xpack.security.enabled: false` is **not
supported**: ECK emits a *"Configuration setting is reserved for internal use"*
warning and ignores your value.

### Don't set `discovery.type: single-node`

ECK auto-injects `cluster.initial_master_nodes` based on `nodeSets[].count`.
With `count: 1` the cluster bootstraps single-node correctly **without** any
help — and explicitly setting `discovery.type: single-node` makes ES crash on
startup with:

```
java.lang.IllegalArgumentException: setting [cluster.initial_master_nodes]
is not allowed when [discovery.type] is set to [single-node]
```

Just leave `count: 1` and let ECK handle discovery.

### ES version pinning — 7.x is EOL but still works (with a warning)

ECK 3.3.0 (PR [#9038](https://github.com/elastic/cloud-on-k8s/pull/9038))
removed ES 7.17 from the supported-versions **docs and test matrix**, but the
actual version gate in
[`pkg/controller/elasticsearch/version/supported_versions.go`](https://github.com/elastic/cloud-on-k8s/blob/v3.5.0/pkg/controller/elasticsearch/version/supported_versions.go)
still accepts any `7.0.0`–`7.99.99` (`case 7` branch verified in v3.5.0).

Behaviour on `spec.version: 7.17.x`:
- Hard validation gate: ✅ accepted (resource applies cleanly)
- Non-blocking admission warning printed on every reconcile:
  `"Version 7.17.x is EOL and support for it will be removed in a future
  release of the ECK operator"`

We accept the warning as harmless noise. Chart version is pinned in
`elasticsearch-operator.tf` so a future `helm upgrade` can't silently pull
an ECK release that finally drops the `case 7` branch. ES 8.x is **not** a
drop-in upgrade — apps using the typed API (`type: '_doc'`) like Huly's
`@hcengineering/elastic` adapter would need source changes.

### Plugins are installed via init container

Unlike the OpenSearch operator (which exposes `spec.general.pluginsList`),
ECK has no native plugin-list field. Install plugins with an init container
in `podTemplate.spec.initContainers` running
`bin/elasticsearch-plugin install --batch <name>`. The volume layout makes
the plugin persist across container restarts but **not** across pod
recreations — keep the init container idempotent.

### Hibernation

ECK has no native `suspend`/`hibernate` field on the `Elasticsearch` CRD, and
the `eck.k8s.elastic.co/suspend` annotation only stops the ES *process* for
debugging (pods stay up). The naive "scale the operator to 0, scale the sts to
0, restore the operator and let ECK bring the pods back" pattern **wedges
permanently on single-master ES 7.x clusters**: ECK's upscale path must call
the ES API to enumerate nodes (one-at-a-time master safety), the API is
unreachable at 0 pods, so the CR loops `"Upscaling StatefulSet ... from 0 to 1"`
and the sts stays at 0 replicas forever (observed for 5 days straight on
huly/elastic; see elastic/cloud-on-k8s#8939 — the fix there only landed for
ES 8+).

Working pattern (implemented in `.github/workflows/databases-hibernate.yml`) —
the workflow owns the sts replicas for the whole window, and ECK is paused via
the 3.5+ `eck.k8s.elastic.co/pause-orchestration` annotation so it never has to
re-upscale from 0 itself:

1. `kubectl annotate elasticsearch <cr> eck.k8s.elastic.co/pause-orchestration=true`
   — pauses sts spec changes/rollups/scale only; certs, services, users and
   health monitoring keep running (the operator stays up, unlike the old
   pattern).
2. Scale the ES `StatefulSet` (labeled
   `elasticsearch.k8s.elastic.co/cluster-name=<name>`) to 0. PVCs are retained
   automatically (ECK sets `persistentVolumeClaimRetentionPolicy: Retain`).
3. On wake: scale the sts back to `spec.nodeSets[].count` for its nodeSet
   (sts name is `<cr>-es-<nodeSet>`) **while still paused**.
4. Wait for pods Ready, then remove the annotation; ECK resumes and the CR
   settles to `phase: Ready`.

The annotation is per-CR and persists across the hibernate/restart workflow
invocations (they are separate `workflow_call`s), so it doubles as the
window-state marker between the two legs.
