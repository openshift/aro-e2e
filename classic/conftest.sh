#!/usr/bin/env bash

function get-kubeconfig {
    echo "Getting cluster kubeconfig"
    RESOURCE_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_CLUSTER_RESOURCE_GROUP}/providers/Microsoft.RedHatOpenShift/openShiftClusters/${ARO_CLUSTER_NAME}"
    curl -X POST \
        -k "${RP_ENDPOINT}${RESOURCE_ID}/listadmincredentials?api-version=2023-11-22" \
        --cert ./secrets/dev-client.pem \
        --header "Content-Type: application/json" \
        --silent | jq -r .kubeconfig | base64 -d > kubeconfig
}

function cluster-conftest {
    echo "Run OCP conformance tests"

    get-kubeconfig
    KUBECONFIG=./kubeconfig
    # TODO - replace the below with actual tests
    oc --insecure-skip-tls-verify get nodes
}

## Run function called from command line. ie: `conftest.sh cluster-conftest
case $1 in
    cluster-conftest)
        cluster-conftest
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
