################################################################################
## General Settings
##

## CONTAINER_ENGINE - **REQUIRED**
## Default: podman
## Values: podman, docker
##
## Set the installed container engine. If you are using Fedora or RHEL et to podman.
## If on MacOS or other Linux distrobution set to docker.
export CONTAINER_ENGINE=podman

## CONTAINER_ENGINE_OPTS - **REQUIRED**
## Default: --platform linux/amd64
##
## Options used by the container engine.
export CONTAINER_ENGINE_OPTS='--platform linux/amd64'

################################################################################
## Openshift CI Settings
##

# OPENSHIFT_CI_TOKEN - **REQUIRED**
# You can get this token from https://console-openshift-console.apps.ci.l2s4.p1.openshiftapps.com/
# by clicking on your name in the top right corner and then "Copy login command".
# After logging in you will be able to display your API token. These API tokens 
# do expire after some time.
export OPENSHIFT_CI_TOKEN=''

