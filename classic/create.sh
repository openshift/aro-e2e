#!/usr/bin/env bash

function create-cluster {
    echo "Create ARO cluster with RP"
}

function mock-create-cluster {
    echo "Create ARO like cluster"
}

## Run function called from command line. ie: `create.sh mock-create-cluster`
case $1 in
    create-cluster)
        create-cluster
    ;;
    mock-create-cluster)
        mock-create-cluster
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
