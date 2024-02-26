#!/usr/bin/env bash

function cluster-conftest {
    echo "Run OCP conformance tests"
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
