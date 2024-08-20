#!/usr/bin/env bash

function create-cluster {
    echo "Create ARO cluster with RP"
    set -eu

    echo "Creating cluster service principal with name ${ARO_CLUSTER_SERVICE_PRINCIPAL_NAME}"
    az ad sp create-for-rbac --name "${ARO_CLUSTER_SERVICE_PRINCIPAL_NAME}" > cluster-service-principal.json
    CSP_CLIENTID=$(jq -r '.appId' cluster-service-principal.json)
    CSP_CLIENTSECRET=$(jq -r '.password' cluster-service-principal.json)
    CSP_OBJECTID=$(az ad sp show --id ${CSP_CLIENTID} -o json | jq -r '.id')
    rm cluster-service-principal.json

    echo "Creating role assignments for cluster service principal"
    SCOPE="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_CLUSTER_RESOURCE_GROUP}"
    az role assignment create \
        --role 'User Access Administrator' \
        --assignee-object-id ${CSP_OBJECTID} \
        --scope ${SCOPE} \
        --assignee-principal-type 'ServicePrincipal'

    az role assignment create \
        --role 'Contributor' \
        --assignee-object-id ${CSP_OBJECTID} \
        --scope ${SCOPE} \
        --assignee-principal-type 'ServicePrincipal'

    echo "Registering cluster version ${ARO_VERSION} to the RP"
    curl -X PUT \
        -k "${RP_ENDPOINT}/admin/versions" \
        --cert ./secrets/dev-client.pem \
        --header "Content-Type: application/json" \
        --data-binary @- <<EOF
{
    "properties": { 
        "version": "${ARO_VERSION}", 
        "enabled": true, 
        "openShiftPullspec": "${ARO_VERSION_OPENSHIFT_PULLSPEC}", 
        "installerPullspec": "${ARO_VERSION_INSTALLER_PULLSPEC}" 
    }
}
EOF

    echo "Creating cluster"
    RESOURCE_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_CLUSTER_RESOURCE_GROUP}/providers/Microsoft.RedHatOpenShift/openShiftClusters/${ARO_CLUSTER_NAME}"
    RANDOM_ID=$(tr -dc a-z </dev/urandom | head -c 1; tr -dc a-z0-9 </dev/urandom | head -c 7)
    MANAGED_RESOURCE_GROUP_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/aro-${RANDOM_ID}"
    VNET_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_CLUSTER_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/cluster-vnet"
    MASTER_SUBNET_ID="${VNET_ID}/subnets/master"
    WORKER_SUBNET_ID="${VNET_ID}/subnets/worker"

    curl -X PUT \
        -k "${RP_ENDPOINT}${RESOURCE_ID}?api-version=2023-11-22" \
        --cert ./secrets/dev-client.pem \
        --header "Content-Type: application/json" \
        --data-binary @- <<EOF
{
    "location": "eastus",
    "properties": {
        "clusterProfile": {
            "domain": "${RANDOM_ID}", "resourceGroupId": "${MANAGED_RESOURCE_GROUP_ID}",
            "version": "${ARO_VERSION}", "fipsValidatedModules": "Disabled"
        },
        "servicePrincipalProfile": {"clientId": "${CSP_CLIENTID}", "clientSecret": "${CSP_CLIENTSECRET}"},
        "networkProfile": {"podCidr": "10.128.0.0/14", "serviceCidr": "172.30.0.0/16"},
        "masterProfile": {
            "vmSize": "Standard_D8s_v3", "subnetId": "${MASTER_SUBNET_ID}", "encryptionAtHost": "Disabled"
        },
        "workerProfiles": [{
            "name": "worker", "count": 3, "diskSizeGb": 128,
            "vmSize": "Standard_D2s_v3", "subnetId": "${WORKER_SUBNET_ID}", "encryptionAtHost": "Disabled"
        }],
        "apiserverProfile": {"visibility": "Public"},
        "ingressProfiles": [{"name": "default", "visibility": "Public"}]
    }
}
EOF

    echo "Waiting for cluster creation to complete..."
    while true
    do
        STATE=$(curl -X GET \
            -k "${RP_ENDPOINT}${RESOURCE_ID}?api-version=2023-11-22" \
            --cert ./secrets/dev-client.pem \
            --silent | jq -r '.properties.provisioningState')

        case $STATE in
            "Creating")
                sleep 30
            ;;
            "Succeeded")
                echo "Cluster creation completed successfully"
                break
            ;;
            *)
                echo "Cluster creation in unexpected state: ${STATE}"
                exit 1
            ;;
        esac
    done
}

## Run function called from command line. ie: `create.sh mock-create-cluster`
case $1 in
    create-cluster)
        create-cluster
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
