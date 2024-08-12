#!/usr/bin/env bash

function config-workflow {
    echo "Workflow config for Classic ARO cluster installs"
}

function secrets {
    if [[ ! -v SECRET_SA_ACCOUNT_NAME ]]; then
        echo ">> SECRET_SA_ACCOUNT_NAME is not set"
        exit 1
    fi
    rm -rf secrets
    az storage blob download -n secrets.tar.gz -c secrets -f secrets.tar.gz --account-name ${SECRET_SA_ACCOUNT_NAME} >/dev/null
    tar -xzf secrets.tar.gz
    rm secrets.tar.gz
}

## Run function called from command line. ie: `config.sh config-workflow`
case $1 in
    config-workflow)
        config-workflow
    ;;
    secrets)
        secrets
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
