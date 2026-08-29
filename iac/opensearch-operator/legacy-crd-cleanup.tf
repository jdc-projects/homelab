# Orphaned CRD cleanup: chart 2.8.4 installed the opensearch.opster.io CRD
# family via helm's crds/ directory (not tofu-tracked). The 3.0.2 upgrade
# replaced them with the opensearch.org/v1 family but helm never deletes CRDs
# a chart no longer ships, so the legacy group lingers with zero objects.
#
# It is not inert residue: the 3.0.x operator still runs its opster.io→org
# migration path when the legacy CRDs exist, and that one-time adoption write
# rewrites a fresh OpenSearchCluster spec from the lossy legacy type mapping -
# dropping fields the legacy API never had (observed: spec.bootstrap.storageClass
# vanished at cluster creation, leaving the operator's bootstrap PVC classless
# on a cluster with no default StorageClass -> the PVC Pending-forever -> the
# bootstrap node never forms -> every data node waits on a phantom
# cluster-manager forever). xitter is the first workload to cold-form on this
# operator; migration-era clusters (posthog) were hibernate-restores and never
# hit it.
#
# Idempotent: kubectl --ignore-not-found makes re-runs no-ops, so this runs
# once per state lifetime and future applies are clean.
resource "null_resource" "legacy_opensearch_crd_cleanup" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl delete crd \
        opensearchactiongroups.opensearch.opster.io \
        opensearchclusters.opensearch.opster.io \
        opensearchcomponenttemplates.opensearch.opster.io \
        opensearchindextemplates.opensearch.opster.io \
        opensearchismpolicies.opensearch.opster.io \
        opensearchroles.opensearch.opster.io \
        opensearchsnapshotpolicies.opensearch.opster.io \
        opensearchtenants.opensearch.opster.io \
        opensearchuserrolebindings.opensearch.opster.io \
        opensearchusers.opensearch.opster.io \
        --ignore-not-found
    EOT
  }
}
