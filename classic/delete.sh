#!/usr/bin/env bash

function delete-cluster {
    echo "Delete ARO cluster with RP"
    set -eu

    RESOURCE_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_CLUSTER_RESOURCE_GROUP}/providers/Microsoft.RedHatOpenShift/openShiftClusters/${ARO_CLUSTER_NAME}"

    CSP_CLIENTID=$(curl -X GET \
            -k "${RP_ENDPOINT}${RESOURCE_ID}?api-version=2023-11-22" \
            --cert ./secrets/dev-client.pem \
            --silent | jq -r '.properties.servicePrincipalProfile.clientId')
    CSP_OBJECTID=$(az ad sp show --id ${CSP_CLIENTID} -o json | jq -r '.id')

    echo "Deleting cluster"
    curl -X DELETE \
        -k "${RP_ENDPOINT}${RESOURCE_ID}?api-version=2023-11-22" \
        --cert ./secrets/dev-client.pem

    echo "Waiting for cluster deletion to complete..."
    while true
    do
        STATE=$(curl -X GET \
            -k "${RP_ENDPOINT}${RESOURCE_ID}?api-version=2023-11-22" \
            --cert ./secrets/dev-client.pem \
            --silent | jq -r '.properties.provisioningState')

        case $STATE in
            "Deleting")
                sleep 30
            ;;
            "null")
                echo "Cluster deletion completed successfully"
                break
            ;;
            *)
                echo "Cluster deletion in unexpected state: ${STATE}"
                exit 1
            ;;
        esac
    done

    echo "Deleting CSP role assignments"
    SCOPE="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_CLUSTER_RESOURCE_GROUP}"
    az role assignment delete --assignee ${CSP_OBJECTID} --scope ${SCOPE}

    echo "Deleting CSP"
    az ad app delete --id ${CSP_CLIENTID}
}

function mock-delete-cluster {
    echo "Delete ARO like cluster"
}

## Run function called from command line. ie: `delete.sh mock-delete-cluster`
case $1 in
    delete-cluster)
        delete-cluster
    ;;
    mock-delete-cluster)
        mock-delete-cluster
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
