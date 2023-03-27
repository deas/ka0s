KUBECTL=kubectl
KUBECTL_PATCH=$(KUBECTL) -n $(LITMUS_NS) patch --type=json
CA_CERTS_FILE=/etc/ssl/certs/ca-certificates.crt
SSH_PUB_KEY=keys/id_rsa-ka0s.pub
LITMUS_NS=litmus
LITMUS_SERVER_DEPLOYMENT=litmus-server
PATCH_LITMUS_CA_CERTS=assets/patch-litmus-ca-certs.yaml
PATCH_LITMUS_SERVER_PROXY=assets/patch-litmus-server-proxy.yaml

.DEFAULT_GOAL := help

.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: gen-keys
gen-keys: ## Generate ssh keys
	./script/gen-keys.sh

.PHONY: gh-add-deploy-key
gh-add-deploy-key: ## Add Deployment key to github
	gh repo deploy-key add keys $(SSH_PUB_KEY)

.PHONY: image-summary
image-summary: ## Show deployed images
	$(KUBECTL) get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | grep -v quay.io/openshift/okd-content | sort | uniq -c | sort -n | tac

target:
	mkdir target

# /usr/local/share/ca-certificates/extra/mitmproxy-ca-cert.crt
.PHONY: create-ca-res
create-ca-res: target/manifest-ca-certs.yaml

target/manifest-ca-certs.yaml: target ## Recreate ca certs manifests
	cat $(CA_CERTS_FILE) | $(KUBECTL) create configmap ca-certs --from-file=ca-certificates.crt=/dev/stdin --dry-run=client -o yaml > target/manifest-ca-certs.yaml

.PHONY: recreate-litmus-ca-res
recreate-litmus-ca-res: target/manifest-ca-certs.yaml ## Re-create litmus ca certs
	$(KUBECTL) -n $(LITMUS_NS) delete configmap ca-certs || true
	$(KUBECTL) -n $(LITMUS_NS) create -f target/manifest-ca-certs.yaml
#	$(KUBECTL) -n $(LITMUS_NS) delete secret ca-certs || true
#	cat $(CA_CERTS_FILE) | $(KUBECTL) -n $(LITMUS_NS) create secret generic ca-certs --from-file=ca-certificates.crt=/dev/stdin

.PHONY: patch-litmus-ca-certs
patch-litmus-ca-certs: ## Patch litmus ca certs
	$(KUBECTL_PATCH) deployment $(LITMUS_SERVER_DEPLOYMENT) --patch-file $(PATCH_LITMUS_CA_CERTS)

.PHONY: patch-litmus-proxy-env
patch-litmus-proxy-env: ## Patch litmus proxy env
	$(KUBECTL_PATCH) deployment $(LITMUS_SERVER_DEPLOYMENT) --patch-file $(PATCH_LITMUS_SERVER_PROXY)

.PHONY: create-locust-configmap
create-locust-configmap: ## Create locust ConfigMap
	@$(KUBECTL) -n loadtest create configmap locust --from-file=locustfile.py=./app-manifest/locustfile.py -o yaml --dry-run=client

.PHONY: create-dashboard-configmaps
create-dashboard-configmaps: ## Create dashbaord ConfigMaps
#	$(KUBECTL) -n monitoring create configmap dashboards-istio --from-file=./infrastructure/lib/observability/dashboards/istio -o yaml --dry-run=client > ./infrastructure/lib/observability/configmap-dashboards-istio.yaml
	$(KUBECTL) -n monitoring create configmap dashboards-sock-shop --from-file=./infrastructure/lib/observability/dashboards/sock-shop -o yaml --dry-run=client > ./infrastructure/lib/observability/configmap-dashboards-sock-shop.yaml
	@echo
	@echo "Make sure to add label for grafana sidecar"
	@echo

.PHONY: workload-labels
workload-labels:
	kubectl -n $(LITMUS_NS) get deployments -o=json | jq '.items[] | {kind: .kind, name: .metadata.name, labels: .metadata.labels}'
	kubectl -n $(LITMUS_NS) get sts -o=json | jq '.items[] | {kind: .kind, name: .metadata.name, labels: .metadata.labels}'


.PHONY: fmt
fmt: ## Format
	terraform fmt --check --recursive

.PHONY: lint
lint: ## Lint
	tflint --recursive

PHONY: validate
validate: ## Validate YAML
	./scripts/validate.sh	