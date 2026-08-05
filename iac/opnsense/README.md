# OPNsense

Basic setup for initial OPNsense setup. Doesn't do any configuration, and shouldn't be rerun.
For this reason, it isn't included in the deployment pipeline.

## Prerequisites

- Normal requirements for any other deployment in this repo (e.g. Kubeconfig)
- Uncomment installer disk lines in `vm.tf` (need to be commented again after install is complete)
- `kubectl` installed
- `virtctl` installed
- It may also be necessary to enable any SFP modules, depending on the NIC (example [here](https://nickcharlton.net/posts/unsupported-sfp-modules-intel-x520-debian-freebsd))

## Restore from config.xml

- Copy `config.xml` into this directory
- Uncomment `null_resource.config_xml` references (and installer image references) in the VM definition
- `tofu apply`
- `virtctl -n opnsense console opnsense`
- Press any key when the prompt for the config import comes up
- Enter `cd0`
- Continue install as normal
