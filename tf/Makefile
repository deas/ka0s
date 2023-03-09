# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Please note that this file was generated from [terraform-google-module-template](https://github.com/terraform-google-modules/terraform-google-module-template).
# Please make sure to contribute relevant changes upstream!

# Make will use bash instead of sh
SHELL := /usr/bin/env bash

DOCKER_TAG_VERSION_DEVELOPER_TOOLS := 1.3
DOCKER_IMAGE_DEVELOPER_TOOLS := cft/developer-tools
REGISTRY_URL := gcr.io/cloud-foundation-cicd
TF_PLUGINS_NAME := tf-plugins-ka0s
TF_PLUGINS_IMAGE := deas/$(TF_PLUGINS_NAME):latest

DEFAULT_GOAL := help

.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# Enter docker container for local development
#.PHONY: docker_run
#docker_run:
#	docker run --rm -it \

# Execute prepare tests within the docker container
#		-e TF_VAR_folder_id \
#		-e TF_VAR_billing_account \

#.PHONY: docker_test_prepare
#docker_test_prepare:
#	docker run --rm -it \

# Clean up test environment within the docker container
#.PHONY: docker_test_cleanup
#docker_test_cleanup:
#	docker run --rm -it \

# Execute integration tests within the docker container
#.PHONY: docker_test_integration
#docker_test_integration:
#	docker run --rm -it \

.PHONY: docker-build-tf-plugins
docker-build-tf-plugins: ## Build terraform plugin image for restricted environments
	docker build --tag $(TF_PLUGINS_IMAGE) .

.PHONY: docker-import-tf-plugins
docker-import-tf-plugins: ## Pull and extract terraform plugins
	docker pull $(TF_PLUGINS_IMAGE)
	docker rm $(TF_PLUGINS_NAME) || true
	docker create --name $(TF_PLUGINS_NAME) $(TF_PLUGINS_IMAGE)
	rm -rf plugin-cache
	docker cp $(TF_PLUGINS_NAME):/plugin-cache .
	docker rm $(TF_PLUGINS_NAME)

.PHONY: docker-test-lint
docker-test-lint: ## Lint within docker container
	docker run --rm -it \
		-v $(CURDIR):/workspace \
		$(REGISTRY_URL)/${DOCKER_IMAGE_DEVELOPER_TOOLS}:${DOCKER_TAG_VERSION_DEVELOPER_TOOLS} \
		/usr/local/bin/test_lint.sh

.PHONY: docker-generate-docs
docker-generate-docs: ## Generate documentation
	docker run --rm -it \
		-v $(CURDIR):/workspace \
		$(REGISTRY_URL)/${DOCKER_IMAGE_DEVELOPER_TOOLS}:${DOCKER_TAG_VERSION_DEVELOPER_TOOLS} \
		/bin/bash -c 'source /usr/local/bin/task_helper_functions.sh && generate_docs'

.PHONY: apply
apply: ## Terraform apply
	terraform apply -auto-approve

.PHONY: quick-destroy
quick-destroy: ## Quick destruction
	docker stop ka0s-control-plane || true
	docker rm ka0s-control-plane || true
	rm -rf 	terraform.tfstate*

.PHONY: open-app
open-app: ## Open the application in your browser
	open http://$$(kubectl -n litmus get svc litmus-frontend-service --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):9091
