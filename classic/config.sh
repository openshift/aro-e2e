#!/usr/bin/env bash

function config-workflow {
    echo "Workflow config for Classic ARO cluster installs"
}

## Run function called from command line. ie: `config.sh config-workflow`
case $1 in
    config-workflow)
        config-workflow
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
