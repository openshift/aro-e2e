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

################################################################################
## ARO Classic Environment Settings
##

# SECRET_SA_ACCOUNT_NAME - **REQUIRED**
# The name of the storage account in Azure containing secrets necessary
# to access the classic RP instance used to provision clusters.
export SECRET_SA_ACCOUNT_NAME=''

# AZURE_SUBSCRIPTION_ID - **REQUIRED**
# The UUID of the subscription in Azure to create the cluster+backing resources
# within. Generally this will be the same subscription as the RP instance used
# to provision clusters is in.
export AZURE_SUBSCRIPTION_ID=''

# AZURE_CLUSTER_RESOURCE_GROUP
# Default: aro-${USER}
# The name of the resource group to install the cluster resources (vnet) within.
# It will be created and deleted as a part of the workflow.
export AZURE_CLUSTER_RESOURCE_GROUP="aro-${USER}"

# ARO_CLUSTER_SERVICE_PRINCIPAL_NAME
# Default: aro-${USER}-csp
# The name of the EntraID application to use as the cluster service principal.
# It will be created and deleted as a part of the workflow.
export ARO_CLUSTER_SERVICE_PRINCIPAL_NAME="aro-${USER}"

# ARO_CLUSTER_NAME
# Default: aro-${USER}
# The name of the EntraID application to use as the cluster service principal.
# It will be created and deleted as a part of the workflow.
export ARO_CLUSTER_NAME="aro-${USER}"

# ARO_VERSION - **REQUIRED**
# The name of the ARO version to install, generally in the format:
# `${OCP_VERSION}-${HASH}`. where $OCP_VERSION corresponds to an OCP X.Y.Z
# release, and $HASH corresponds to the specific Git commit ref for an
# installer-aro-wrapper image.
export ARO_VERSION=''

# ARO_VERSION_OPENSHIFT_PULLSPEC - **REQUIRED**
# A reference to an ocp-release image, corresponding to the OCP version defined
# in ARO_VERSION.
export ARO_VERSION_OPENSHIFT_PULLSPEC=''

# ARO_VERSION_INSTALLER_PULLSPEC - **REQUIRED**
# A reference to an aro-installer image (built from openshift/installer-aro-wrapper),
# corresponding to the OCP y-stream for the OCP version defined in ARO_VERSION.
export ARO_VERSION_INSTALLER_PULLSPEC=''
