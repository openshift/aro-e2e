#!/usr/bin/env bash

function build {
    echo "Build openshift/installer"
}

function build-aro {
    echo "Build openshift/installer-aro"
}

function build-aro-wrapper {
    echo "Build openshift/installer-aro-wrapper"
}

function clean {
    echo "Installer clean"
}

## Run function called from command line. ie: `build.sh build`
case $1 in
    build)
        build
    ;;
    build-aro)
        build-aro
    ;;
    build-aro-wrapper)
        build-aro-wrapper
    ;;
    clean)
        clean
    ;;*)
        echo "No function named $1"
        exit 1
    ;;
esac
