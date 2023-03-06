# ka0s - Building Chaos around LitmusChaos on Kubernetes 🧪

The primary goal of this project is to build a Chaos Engineering environment around the [LitmusChaos](https://litmuschaos.io/) platform. We try hard to provide a smooth development process including GitOps based deployment. Hence, we are leveraging `flux`, `terraform`, `nix` (using [devenv as a nix flake](https://devenv.sh/guides/using-with-flakes/)) and `kind` (maybe `k3s` soon). `nix` is no requirement, but strongly recommended as it should automatically provide you with the other tools - you should not have to worry about how to install things with your package manager.

Experimentation is a natural element of Chaos Engineering. However, it should be just as natural in Software Development in general. That is why you might encounter bits (such as knative) with no strong Chaos Engineering relationship in this repo. Those bits are meant to be optional.

This repo is derived from [flux-conductr](https://github.com/deas/flux-conductr). Look at that, if you are after a similar experience, focused on `flux` specifically.

Even though, we am trying to cover most things declaratively, some random bits may be covered by `make` targets. Simply calling the default target:

```sh
make
```
should output help hinting at what is covered.

You may also want to disable github actions to start.

## Bootrapping
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

I use `mitmproxy` locally to try things out.

## Known Issues
- knative challenging (Some bits need `kustomize.toolkit.fluxcd.io/substitute: disabled` in our context, other things need tweaks to upstream yaml to play with GitOps "... configured")

## TODO
- There are TODO tags in the code
- Add first class support for `mitmproxy` (ship deployment)
- Add first class support for remote agent?
- Leverage prometheus properly
- Add GitOps experiments
- Manifests Naming
- Split up `tf` module?
- Fix annoying terraform plan ` yaml_incluster `

## Know Issues
- Knative deployment straight from github deployment not possible

## Misc/Random Bits
- https://istio.io/latest/docs/setup/install/helm
- https://docs.cilium.io/en/stable/network/istio/
- https://knative.dev/docs/install/installing-istio/#installing-istio
- Deploy knative straight from github? like flux-monitoring.yaml?
- [Running Knative with Istio in a Kind Cluster (old!)](https://www.arthurkoziel.com/running-knative-with-istio-in-kind/)
- [Install Knative using quickstart](https://knative.dev/docs/getting-started/quickstart-install/)
