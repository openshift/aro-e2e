SHELL = /bin/bash

.PHONY: default
default: help config-load ;

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
	@echo "build"

run: ## Run aro-e2e environment (interactive mode)
	@echo "aro-e2e run"

ci:	## Run default CI workflow
	@echo "ci workflow"

clean: ## Clean the aro-e2e environment
	@echo "clean"

config-create: ## Create a configuration file for aro-e2e with your user and the default settings.
	cp config_example.sh config_$(USER).sh

config-load: ## Load the config_$USER file
ifneq (,$(wildcard ./config_$(USER).sh))
	./config_$(USER).sh 
else
	@echo "File config_$(USER).sh does not exist run 'make config-create' to create a config file for your user"
endif

################################################################################
## Installer Targets
##

installer-build: ## Build openshift installer image
	@echo "installer build"

installer-build-aro-wrapper: ## Build installer-aro-wrapper image
	@echo "installer-aro-wrapper build"

installer-clean: ## Remove installer artifacts from the aro-e2e environment
	@echo "installer clean"

################################################################################
## Classic RP Targets
##

classic-bootstrap-azure: 
	@echo "Bootstrap azure resources for ARO install with RP"

classic-create:
	@echo "Create ARO cluster with RP"

classic-conftest: ## Run Openshift conformance tests
	@echo "Run Openshift conformance tests"

classic-delete:
	@echo "Delete ARO cluster with RP"

classic-mock-bootstrap-azure: ## Bootstrap Azure resources for Classic ARO like cluster
	@echo "Bootstrap azure resources for ARO like cluster"

classic-mock-create: ## Create Classic ARO like cluster for testing
	@echo "Create ARO like cluster"

classic-mock-delete: ## Delete Classic ARO like cluster for testing
	@echo "Delete ARO like cluster"

################################################################################
## Workflow Targets
##

wf-classic-config:
	@echo "workflow config for classic installs"

wf-classic-cluster-conftest: ## Openshift conformance test workflow (Classic ARO using RP)
	$(MAKE) wf-classic-config classic-bootstrap-azure classic-create classic-conftest classic-delete

wf-classic-mock-cluster-conftest: ## Openshift conformance test workflow (Classic ARO like)
	$(MAKE) wf-classic-config classic-mock-bootstrap-azure classic-mock-create classic-conftest classic-mock-delete

