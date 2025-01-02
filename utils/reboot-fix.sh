# temporary script to run after rebooting to deal with startup issues
kubectl -n openebs delete pods --all &
kubectl -n crowdsec delete pods --all &
