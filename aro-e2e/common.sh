#!/usr/bin/env bash

function build {
    echo "Build aro-e2e"
}

function ci {
    echo "aro-e2e ci"
}

function clean {
    echo "aro-e2e clean"
}

function run {
    echo "Run aro-e2e"
}


## Run function called from command line. ie: `common.sh build`
case $1 in
    build)
        build
    ;;
    ci)
        ci
    ;;
    clean)
        clean
    ;;
    run)
        run
    ;;
        *)
        echo "No function named $1"
        exit 1
    ;;
esac
