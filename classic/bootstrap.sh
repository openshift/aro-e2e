#!/usr/bin/env bash

function bootstrap-azure {
    echo "Bootstrap Azure resources for ARO install with RP"
    set -e

    if [[ -z "${AZURE_SUBSCRIPTION_ID}" ]]; then
        echo ">> AZURE_SUBSCRIPTION_ID is not set"
        exit 1
    fi

    if [[ -z "${AZURE_CLUSTER_RESOURCE_GROUP}" ]]; then
        echo ">> AZURE_CLUSTER_RESOURCE_GROUP is not set"
        exit 1
    fi

    echo "Creating resource group ${AZURE_CLUSTER_RESOURCE_GROUP}"
    az group create \
        --subscription ${AZURE_SUBSCRIPTION_ID} \
        --resource-group ${AZURE_CLUSTER_RESOURCE_GROUP} \
        --location eastus

    echo "Creating cluster resources"
    az deployment group create \
        --subscription ${AZURE_SUBSCRIPTION_ID} \
        --resource-group ${AZURE_CLUSTER_RESOURCE_GROUP} \
        --name cluster-resources \
        --template-file ./classic/bootstrap.bicep
}

function clean-bootstrap-azure {
    echo "Cleaning bootstrap Azure resources for ARO install with RP"
    set -e

    if [[ -z "${AZURE_SUBSCRIPTION_ID}" ]]; then
        echo ">> AZURE_SUBSCRIPTION_ID is not set"
        exit 1
    fi

    if [[ -z "${AZURE_CLUSTER_RESOURCE_GROUP}" ]]; then
        echo ">> AZURE_CLUSTER_RESOURCE_GROUP is not set"
        exit 1
    fi

    echo "Deleting cluster resource group"
    az group delete --yes \
        --subscription ${AZURE_SUBSCRIPTION_ID} \
        --resource-group ${AZURE_CLUSTER_RESOURCE_GROUP}
}

function mock-bootstrap-azure {
    echo "Bootstrap Azure resources for ARO like cluster"
}

## Run function called from command line. ie: `boostrap.sh mock-bootstrap-azure`
case $1 in
    bootstrap-azure)
        bootstrap-azure
    ;;
    clean-bootstrap-azure)
        clean-bootstrap-azure
    ;;
    mock-bootstrap-azure)
        mock-bootstrap-azure
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
