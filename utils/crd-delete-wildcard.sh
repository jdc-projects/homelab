{
MATCH_STRING="PLACEHOLDER"
kubectl get crds -oname | grep "$MATCH_STRING" | xargs kubectl delete
}