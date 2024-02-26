#!/usr/bin/env bash

function delete-cluster {
    echo "Delete ARO cluster with RP"
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
