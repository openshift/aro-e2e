#!/usr/bin/env bash

function cluster-conftest {
    echo "Run OCP conformance tests"
}

## Run function called from command line. ie: `config.sh workflow-classic-config`
case $1 in
    cluster-conftest)
        cluster-conftest
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
