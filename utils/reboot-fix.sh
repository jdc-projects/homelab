# temporary script to run after rebooting to deal with startup issues
kubectl -n openebs delete pods --all &
kubectl -n crowdsec delete pods --all &
kubectl -n traefik delete pods --all &
tofu -chdir=../iac/github-org-runners destroy -auto-approve -input=false && tofu -chdir=../iac/github-org-runners apply -auto-approve -input=false
