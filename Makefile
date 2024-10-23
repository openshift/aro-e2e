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

###############################################################################
## Ansible
##
REGISTRY ?= registry.access.redhat.com
TAG ?= $(shell git describe --exact-match 2>/dev/null)
COMMIT = $(shell git rev-parse --short=7 HEAD)$(shell [[ $$(git status --porcelain) = "" ]] || echo -dirty)
ifeq ($(TAG),)
	VERSION = $(COMMIT)
else
	VERSION = $(TAG)
endif

NO_CACHE ?= true
PODMAN_REMOTE_ARGS ?=
PODMAN_VOLUME_OVERLAY=$(shell if [[ $$(getenforce) == "Enforcing" ]]; then echo ":O"; else echo ""; fi 2>/dev/null)

.PHONY: ansible-image
ansible-image:
	podman $(PODMAN_REMOTE_ARGS) \
		build . \
		-f Dockerfile.ansible \
		--build-arg REGISTRY=$(REGISTRY) \
		--build-arg VERSION=$(VERSION) \
		--no-cache=$(NO_CACHE) \
		--tag aro-ansible:$(VERSION)

LOCATION ?= eastus
CLUSTERPREFIX ?= $(USER)
CLUSTERPATTERN ?= basic
CLEANUP := False
INVENTORY := "hosts.yaml"
SSH_CONFIG_DIR := $(HOME)/.ssh/
SSH_KEY_BASENAME := id_rsa
ifneq ($(CLUSTERPATTERN),*)
	CLUSTERFILTER = -l $(CLUSTERPATTERN)
endif
ifeq ($(VERBOSE),False)
	SKIP_VERBOSE = --skip-tags verbose
endif

.PHONY: cluster
cluster: cluster-deploy cluster-cleanup
	@true
.PHONY: cluster-deploy
cluster-deploy:
	podman $(PODMAN_REMOTE_ARGS) \
		run \
		--rm \
		-it \
		-v $${AZURE_CONFIG_DIR:-~/.azure}:/opt/app-root/src/.azure$(PODMAN_VOLUME_OVERLAY) \
		-v ./ansible:/ansible$(PODMAN_VOLUME_OVERLAY) \
		-v $(SSH_CONFIG_DIR):/root/.ssh$(PODMAN_VOLUME_OVERLAY) \
		-v ./ansible_collections/azureredhatopenshift/cluster/:/opt/app-root/src/.local/share/pipx/venvs/ansible/lib/python3.11/site-packages/ansible_collections/azureredhatopenshift/cluster$(PODMAN_VOLUME_OVERLAY) \
		aro-ansible:$(VERSION) \
			-i $(INVENTORY) \
			$(CLUSTERFILTER) \
			-e location=$(LOCATION) \
			-e CLUSTERPREFIX=$(CLUSTERPREFIX) \
			-e CLEANUP=$(CLEANUP) \
			-e SSH_KEY_BASENAME=$(SSH_KEY_BASENAME) \
			$(SKIP_VERBOSE) \
			deploy.playbook.yaml
.PHONY: cluster-cleanup
cluster-cleanup:
	@if [ "${CLEANUP}" == "True" ]; \
	then \
		podman $(PODMAN_REMOTE_ARGS) \
			run \
			--rm \
			-it \
			-v $${AZURE_CONFIG_DIR:-~/.azure}:/opt/app-root/src/.azure$(PODMAN_VOLUME_OVERLAY) \
			-v ./ansible:/ansible$(PODMAN_VOLUME_OVERLAY) \
			-v $(SSH_CONFIG_DIR):/root/.ssh$(PODMAN_VOLUME_OVERLAY) \
			-v ./ansible_collections/azureredhatopenshift/cluster/:/opt/app-root/src/.local/share/pipx/venvs/ansible/lib/python3.11/site-packages/ansible_collections/azureredhatopenshift/cluster$(PODMAN_VOLUME_OVERLAY) \
			aro-ansible:$(VERSION) \
				-i $(INVENTORY) \
				$(CLUSTERFILTER) \
				-e location=$(LOCATION) \
				-e CLUSTERPREFIX=$(CLUSTERPREFIX) \
				-e CLEANUP=$(CLEANUP) \
				-e SSH_KEY_BASENAME=$(SSH_KEY_BASENAME) \
				$(SKIP_VERBOSE) \
				cleanup.playbook.yaml \
	; fi

.PHONY: lint-ansible
lint-ansible:
	cd ansible; ansible-lint -c .ansible_lint.yaml

.PHONY: test-ansible
test-ansible:
	podman $(PODMAN_REMOTE_ARGS) \
		run \
		--rm \
		--entrypoint ansible-test \
		-v ./ansible_collections/azureredhatopenshift/cluster/:/opt/app-root/src/.local/share/pipx/venvs/ansible/lib/python3.11/site-packages/ansible_collections/azureredhatopenshift/cluster$(PODMAN_VOLUME_OVERLAY) \
		--workdir /opt/app-root/src/.local/share/pipx/venvs/ansible/lib/python3.11/site-packages/ansible_collections/azureredhatopenshift/cluster/ \
		-it \
		aro-ansible:$(VERSION) \
			sanity \
			-v
