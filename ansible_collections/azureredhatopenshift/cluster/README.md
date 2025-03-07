# Ansible Collection - azureredhatopenshift.cluster

## Supported variables

Numerous variables influence the execution of these roles.

Required:

- `name`
- `resource_group`
- `location`: Azure region, e.g. `eastus`. Note that the `Makefile` target `make cluster` sets this based on the environment variable or `make` argument `LOCATION`.
- `CLEANUP` (true/false): Delete the cluster, identities and resource group once the run completes
- `SSH_KEY_BASENAME`: Name of SSH key to pass to the disconnected-cluster-jumphost VM. Example: `id_rsa`. This key is assumed to be in `$(HOME)/.ssh/`.

Optional:

- `aro_api_version`: The API version used to communicate with the ARO RP. Switches cluster creation from az aro cli to the azure_rm_openshiftmanagedcluster Ansible module
- `apiserver_visibility: Public` (`Public`/`Private`): `az aro create --apiserver-visibility`
- `AZAROEXT_VERSION` (version string): Install and use a specific `az aro` extension
- `dns_servers` (list of IP address strings): IP addresses to assign to the created VNET as domain name servers.
- `domain`: Custom DNS domain, see `az aro create --domain`
- `enable_preconfigued_nsg` (true/false)
- `fips_validated_modules`
- `HAS_INTERNET: true` (true*/false)
- `ingress_visibility: Public` (string `Public`/`Private`)
- `lb_ip_count`: `az aro create --load-balancer-managed-outbound-ip-count`
- `master_cidr`
- `master_encryption_at_host: false` (true/false)
- `master_encryption_at_host`
- `master_vm_size`
- `network_prefix_cidr`
- `outbound_type` (string `Loadbalancer` / `UserDefinedRouting`): See `az aro create --outbound-type`
- `routes` - List of `{"name": ..., "address_prefix": ..., "next_hop_type": ...}`: Causes a route table to be created and populated with these entries
- `service_cidr` (IP cidr subnet string)
- `upgrade`: List of upgrade targets. See below for details
- `version` (version string): One of the available versions from `az aro get-versions -l <LOCATION>`
- `worker_cidr`
- `worker_count`
- `worker_encryption_at_host`
- `worker_encryption_at_host`
- `worker_vm_size`

Upgrades:

Upgrades are a list of transitions from a certain version to a new channel and version. Optionally it can apply admin acks or use other flags to `oc adm upgrade`

When clusters do not have internet access (`HAS_INTERNET=false`), additional magic happens. The version's "Pull From: " digest is retrieved and used as an explicit `--to-image` target. The version's signature is also applied as a `ConfigMap` in `openshift-config-managed`

- `from`: Version match to apply upgrade. This is a string prefix match
- `channel`: Channel string, e.g. `stable-4.13`. Note that ARO only officially supports the stable channel.
- `version`: Version to upgrade to, or `latest`. `oc adm upgrade --to`
- `image`: Image to upgrade to `oc adm upgrade --to`
- `admin_acks`: List of admin ack json blobs to apply
- `allow-not-recommended` (true/false): `oc adm upgrade --allow-not-recommended`
- `include-not-recommended` (true/false): `oc adm upgrade --include-not-recommended`
