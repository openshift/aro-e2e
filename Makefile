SHELL = /bin/bash

.PHONY: default
default: help config-check ;

################################################################################
## Configuration Setup
##
## This Makefile uses a configuration file for it's variables. 
## To set up the environment create a copy of `config_example.sh` with your user.
## run `make config-create` or `cp config_example.sh config_$USER.sh`

################################################################################
## aro-e2e Targets
##

## Credit to https://gist.github.com/prwhite/8168133
help: ## Show this help.
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'m

build: ## Build aro-e2e image
	./aro-e2e/common.sh build

run: ## Run aro-e2e environment (interactive mode)
	./aro-e2e/common.sh run

ci:	## Run default CI workflow
	./aro-e2e/common.sh ci

clean: ## Clean the aro-e2e environment
	./aro-e2e/common.sh clean

config-create: ## Create a configuration file for aro-e2e with your user and the default settings.
	cp config_example.sh config_$(USER).sh

config-check: ## Check for the config_$USER.sh file
ifneq (,$(wildcard ./config_$(USER).sh))
	@./config_$(USER).sh 
else
	@echo "File config_$(USER).sh does not exist run 'make config-create' to create a config file for your user"
endif

################################################################################
## Installer Targets
##

installer-build: ## Build openshift installer image
	./installer/build.sh build

installer-build-aro: ## Build installer-aro image
	./installer/build.sh build-aro

installer-build-aro-wrapper: ## Build installer-aro-wrapper image
	./installer/build.sh build-aro-wrapper

installer-build-clean: ## Remove installer artifacts from the aro-e2e environment
	./installer/build.sh clean

################################################################################
## Classic RP Targets
##

classic-secrets:
	./classic/config.sh secrets

classic-bootstrap-azure:
	./classic/bootstrap.sh bootstrap-azure

classic-clean-bootstrap-azure:
	./classic/bootstrap.sh clean-bootstrap-azure

classic-conftest: ## Run Openshift conformance tests
	./classic/conftest.sh cluster-conftest

classic-config-workflow:
	./classic/config.sh config-workflow

classic-create:
	./classic/create.sh create-cluster

classic-delete:
	./classic/delete.sh delete-cluster

################################################################################
## Workflow Targets
##

wf-classic-cluster-conftest: ## Openshift conformance test workflow (Classic ARO using RP)
	$(MAKE) classic-config-workflow classic-bootstrap-azure classic-create classic-conftest classic-delete classic-clean-bootstrap-azure
