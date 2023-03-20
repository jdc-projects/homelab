# homelab

Infrastructure and code for deploying my Homelab. There are some dependencies.

## Prequisites

This system requires that some setup is completed on the first:
* The rule that restricts access to the Kubernetes managements interface must be removed:

```sh
sudo iptables -D INPUT -p tcp -m tcp --dport 6443 -m comment --comment "iX Custom Rule to drop connection requests to k8s cluster from external sources" -j DROP
```

* The Kubernetes management interface port must be exposed to the internet (through router port forwarding)

* The domain jack-chapman.co.uk must point towards my public IP

## Notes

After initial setup, I should make the Kubernetes API inaccessible from the internet.
This will need a route through the ingress to the API.
