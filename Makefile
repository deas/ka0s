KUBECTL=kubectl
CA_CERTS_FILE=/etc/ssl/certs/ca-certificates.crt
SSH_PUB_KEY=keys/id_rsa-ka0s.pub
LITMUS_NS=litmus
LITMUS_DEPLOYMENT=litmus-server
PATCH_LITMUS_PROXY=assets/patch-litmus-server-proxy.yaml
PATCH_LITMUS_CA_CERTS=assets/patch-litmus-server-ca-certs.yaml

.DEFAULT_GOAL := help

.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

#init:
#	git submodule update --init --recursive

.PHONY: get-co
get-co: ## Show Cluster Operators
	$(KUBECTL) get co

.PHONY: gen-keys
gen-keys: ## Generate ssh keys
	./script/gen-keys.sh

.PHONY: gh-add-deploy-key
gh-add-deploy-key: ## Add Deployment key to github
	gh repo deploy-key add keys $(SSH_PUB_KEY)

#.PHONY: approve-csr
#approve-csr: ## Approve Certificate Signing requests
#	$(KUBERCTL) get csr -ojson | \
#	jq -r '.items[] | select(.status == {} ) | .metadata.name' | \
#		xargs $(KUBECTL) adm certificate approve

.PHONY: image-summary
image-summary: ## Show deployed images
	$(KUBECTL) get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | grep -v quay.io/openshift/okd-content | sort | uniq -c | sort -n | tac

# /usr/local/share/ca-certificates/extra/mitmproxy-ca-cert.crt
.PHONY: recreate-ca-res
recreate-ca-res: ## Recreate ca certs resources
#	[ -d "target" ] || mkdir -p "target"
	$(KUBECTL) -n $(LITMUS_NS) delete configmap ca-certs || true
	cat $(CA_CERTS_FILE) | $(KUBECTL) -n $(LITMUS_NS) create configmap ca-certs --from-file=ca-certificates.crt=/dev/stdin
	$(KUBECTL) -n $(LITMUS_NS) delete secret ca-certs || true
	cat $(CA_CERTS_FILE) | $(KUBECTL) -n $(LITMUS_NS) create secret generic ca-certs --from-file=ca-certificates.crt=/dev/stdin
#	--dry-run=client -o yaml > target/manifest-ca-certs.yaml

.PHONY: patch-litmus-server-ca-certs
patch-litmus-server-ca-certs: ## Patch litmus server ca
	$(KUBECTL) -n $(LITMUS_NS) patch deployment $(LITMUS_DEPLOYMENT) --type=json --patch-file $(PATCH_LITMUS_CA_CERTS)

.PHONY: patch-litmus-server-proxy
patch-litmus-server-proxy: ## Patch litmus server proxy
	$(KUBECTL) -n $(LITMUS_NS) patch deployment $(LITMUS_DEPLOYMENT) --type=json --patch-file $(PATCH_LITMUS_PROXY)
