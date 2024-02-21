#!/usr/bin/env bash

function bootstrap-azure {
    echo "Bootstrap Azure resources for ARO install with RP"
}

function mock-bootstrap-azure {
    echo "Bootstrap Azure resources for ARO like cluster"
}

## Run function called from command line. ie: `boostrap.sh mock-bootstrap-azure`
case $1 in
    bootstrap-azure)
        bootstrap-azure
    ;;
    mock-bootstrap-azure)
        mock-bootstrap-azure
    ;;
    *)
        echo "No function named $1"
        exit 1
    ;;
esac
