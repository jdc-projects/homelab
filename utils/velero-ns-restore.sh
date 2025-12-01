(
NAMESPACE=PLACEHOLDER
velero restore create $NAMESPACE-$(date +%Y%m%d-%H%M%S) --from-schedule nightly --include-namespaces $NAMESPACE  --namespace-mappings $NAMESPACE:$NAMESPACE  --existing-resource-policy update --restore-volumes=true
)
