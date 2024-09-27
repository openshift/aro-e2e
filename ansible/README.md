# Reproducibly create ARO clusters

In order to create a cluster, first ensure that you have a valid, logged-in `az` session. The Ansible automation will use the account shown by `az ad signed-in-user show` and the subscription shown by `az account list` (the subscription where `IsDefault` is True)


First, generate an Ansible image using

```shell
$ make ansible-image
```

This creates the required Ansible container image. Next, run

```shell
$ make cluster
```

There are several variables implemented to control aspects of the playbook execution. These can be combined with each other as needed.

To personalize the resulting resource groups, set the `CLUSTERPREFIX` as desired. This variable defaults to your current shell's `$USER`.

```shell
$ make cluster CLUSTERPREFIX=ocpbugs35300
```

The default region used is `eastus`. Set the `REGION` parameter to choose a different region:

```shell
$ make cluster REGION=centraluseuap
```

To choose one or more cluster configurations, set the `CLUSTERPATTERN` parameter to a wildcard string that matches the cluster scenarios you wish to test:

```shell
$ make cluster CLUSTERPATTERN=udr
```

To clean up at the end of the run, set `CLEANUP` to True. This will delete the cluster, the resource group, then the Entra Service Principal and Application. Automation will want to enable this to not leave dangling resources.

```shell
$ make cluster CLEANUP=True
```

Alternate Ansible inventories can be found in `ansible/inventory`, and can be used by specificing their path (relative to the `ansible` directory) by setting the `INVENTORY` parameter:

```shell
$ make cluster INVENTORY=inventory/upgrades-candidate.yaml
```

Currently implemented cluster configurations are:

- `basic`: Simplest cluster, nothing fancy
- `private`: Simple cluster with apiserver and ingress visibility set to private.
- `enc`: Encryption-at-host enabled
- `udr`: UserDefinedRouting with a blackhole Route Table
- `byok`: Disk encryption using bring-your-own-key

Private clusters such as `private` and `udr` will cause the creation of a jumphost to access the cluster API. Your local SSH public key will be passed to the jumphost, then ansible will use your corresponding private key to tunnel SSH through it. If your local SSH configuration differs from defaults, the Makefile supports two variables to tweak things:

```shell
SSH_CONFIG_DIR := $(HOME)/.ssh/
SSH_KEY_BASENAME := id_rsa
```