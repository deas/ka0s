# ka0s - Building Chaos around LitmusChaos on Kubernetes 🧪

The primary goal of this project is to build a Chaos Engineering environment around the [LitmusChaos](https://litmuschaos.io/) platform. We try hard to provide a smooth development process including GitOps based deployment. Hence, we are leveraging `flux`, `terraform`, `nix` (using [devenv as a nix flake](https://devenv.sh/guides/using-with-flakes/)) and `kind` (maybe `k3s` soon). `nix` is no requirement, but strongly recommended as it should automatically provide you with the other tools - you should not have to worry about how to install things with your package manager.

If you just want to kick the Chaos the tires quickly, or if you want to build a long lasting Chaos environment : This might be a place to start.

Experimentation is a natural element of Chaos Engineering. However, it should be just as natural in Software Development in general. That is why you might encounter bits (such as Knative) with no strong Chaos Engineering relationship in this repo. Those are meant to be optional.

The default `localhost` cluster environment has very few requirements. It should work on many types of clusters. However, it is optimized to work with just enough resources to run the whole Chaos Stack and the resilient Sock Shop. 

Various things I built upon had minor issues (mostly because there where outdated). At this time, the "fixes" are here because I wanted to move on quickly. Would be happy to contribute back. 

This repo is derived from [flux-conductr](https://github.com/deas/flux-conductr). Look at that, if you are after a similar experience, focused on `flux` specifically.

## Features
- [LitmusChaos](https://litmuschaos.io/) platform
- This repo acts as a ChaosHub
- We serve the [Sock Shop Microservices Demo Application](https://microservices-demo.github.io/) as a scenario (defaulting to `containerd` experiments)
- Prometheus Stack including Grafana provisioned for the Sock Shop Appliation
- Loki
- Istio Eventing/Serving
- Knative
- [Locust](https://locust.io/) load testing (supporting the UI)
- Portal API usage examples
- Support for deployment in proxy/custom CA environments
- `flux`-/`terraform` Deployment
- `nix` Dev Experience

## Bootrapping
Even though, we am trying to cover most things declaratively, some random bits may be covered by `make` targets. Simply calling the default target:

```sh
make
```
should output help hinting at what is covered.

You may also want to disable github actions to start.

Optional: Generate ssh deployent keys and add public key to your repo

```sh
make gen-keys
make gh-add-deploy-key
```

There is a `terraform` + `kind` based bootstrap in [`tf`](./tf).

```sh
cp sample.tfvars terraform.tfvars
# Set proper values in terraform.tfvars
make apply
```
This should spin up the limus server. Once it is up

```sh
make open-app
```

should open it in your browser.

Alternatively, you can bootstrap or even upgrade an existing cluster (be sure to have current kubecontext set properly). Also, make sure `flux --version` shows desired version.

```sh
./scripts/flux-bootstrap.sh
```

## Proxy / Custom CA support
We aim at supporting environments requiring a proxy (including custom CA certificate chains) to access external services.

A proxy has to be introduced in various places. Many systems (including  `kind`) support configuration via environment variables, namely `HTTPS_PROXY`, `HTTP_PROXY` and `NO_PROXY`.

For `flux`, we ship a [`local-proxy`](./clusters/local-proxy/flux-system/kustomization.yaml) cluster adding that environment. Set this cluster in `tf/terraform.tfvars` to try it.

For `litmus`, we only ship a runtime patch at the moment.

Regarding custom certificates, we simply overlay the compiled file in the containers using a `ConfigMap`. By default, we assume we can generate it on the host executing the initial deployment:

```sh
make -n recreate-ca-res
```

```sh
make -n patch-litmus-ca-certs patch-litmus-proxy-env
```

should give you an idea how we patch a system.

The `terraform` module provides a mechanism to patch the `coredns` `ConfigMap`. This may come in handy when working with a proxy.

I use `mitmproxy` locally to try things out.

## Misc
### Autentication
Grafana : `admin` / `prom-operator`.
Litmus : `admin` / `litmus`.

## TODO
- There are TODO tags in the code
- Leverage `kustomize` with remote repos/resources in workflow (`litmuschaos/k8s:latest` does not yet have `git`) 
- Leverage Istio for failure injection?
- This repo can act as a ChaosHub - add it during setup
- Add first class support for `mitmproxy` (ship deployment)
- Add first class support for remote agent?
- Try GitOps scenarios?
- Add this repo (as branch here - just like `gh_pages`?)
- Manifests Naming
- Fix annoying terraform plan ` yaml_incluster`
- Add knative-serving/eventing/dns (using `nip.io`?)
- How do we manage litmus projects (using ui?)?
- Add mongodb/prometheus convenience (e.g. auth) targets to `Makefile`
- Test drive 3.0-beta
- Introduce kubeconfig module so we don't rely on environment w/o `kind`
- `disk-fill` does not yet play with containerd
- Implement weak-sock-shop
- Catchup scheduled sock-shop workflow
- Try Prometheus alerts
- How would eBPF/Cilium help?
- Introduce istio based tracing

## Known Issues
- Some experiments from `litmus-go` appear to rely on `/var/run/docker.sock` which does not exist with containerd based environments ([see](https://docs.litmuschaos.io/docs/troubleshooting))
- Knative deployment straight from github deployment not possible
- knative challenging (Some bits need `kustomize.toolkit.fluxcd.io/substitute: disabled` in our context, other things need tweaks to upstream yaml to play with GitOps "... configured")
- Istio Ingress appears to have an image pulling issue, so it takes a while to come up

## Misc/Random Bits
- https://istio.io/latest/docs/setup/install/helm
- https://docs.cilium.io/en/stable/network/istio/
- https://knative.dev/docs/install/installing-istio/#installing-istio
- Deploy knative straight from github? like flux-monitoring.yaml?
- [Running Knative with Istio in a Kind Cluster (old!)](https://www.arthurkoziel.com/running-knative-with-istio-in-kind/)
- [Install Knative using quickstart](https://knative.dev/docs/getting-started/quickstart-install/)

