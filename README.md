# ka0s - Experimenting with Chaos on Kubernetes 🧪

The primary goal of this project is to exercise and experiment with Chaos Engineering tools around Kubernetes. Toolchain setup is based on flux and terraform, since I want to enable development. I consider localhost experience (hence `kind` and maybe `k3s` soon) very important. Given that, some elements may be useful in CI context. Most things however, should play nice on bigger or even produtive environments as well. Again, aiming at a smooth dev experience, I am test driving [devenv as a nix flake](https://devenv.sh/guides/using-with-flakes/). The idea here is to bring in required tooling. Hence, you should be good to go if your host has `nix`. For convenience, you may want to add `direnv`.

This repo is based on [flux-conductr](https://github.com/deas/flux-conductr). Look at that, if you are after a similar development experience, but focused specifically on flux itself.

Even though, I am trying to cover most things declaratively, some random bits may be covered by `make` targets. Simply calling the default target:

```sh
make
```

should output help hinting at what is covered.

Generate ssh deployent keys:

```sh
make gen-keys
```
Add public deployment key to github. You may also want to disable github actions to start.

```sh
make gh-add-deploy-key
```

## Bootrapping

There is a `terraform` + `kind` based bootstrap in [`tf`](./tf).

```sh
cp sample.tfvars terraform.tfvars
# Set proper values in terraform.tfvars
terraform apply
```
Alternatively, you can bootstrap or even upgrade an existing cluster (be sure to have current kube context set properly). Also, make sure `flux --version` shows desired version.

```sh
./scripts/flux-bootstrap.sh
```

## Known Issues
- knative challenging (Some bits need `kustomize.toolkit.fluxcd.io/substitute: disabled` in our context, other things need tweaks to upstream yaml to play with GitOps "... configured")

## TODO
- There are TODO tags in the code
- Prometheus/kube-prometheus? Shouldn't istio ship a bit?
- When flux needs to go through a proxy, make sure to enable the patch in `flux-system/kustomization.yaml`
- How to use flux w/o ssh?
- Naming?
- ~~Setup "envs" properly / remove literals~~
- Flux Dashboard?
- [Grafana/Prometheus](https://fluxcd.io/flux/guides/monitoring/)?
- Validation ( -> Monitoring)
- local k3s (Speed?)
- ca cert mount / proxy env
- Remove image-reflector-controller,image-automation-controller, go public

╷
│ Error: flux-system/flux-system failed to create kubernetes rest client for update of resource: resource [source.toolkit.fluxcd.io/v1beta2/GitRepository] isn't valid for cluster, check the APIVersion and Kind fields are valid
│ 
│   with module.flux.kubectl_manifest.sync["source.toolkit.fluxcd.io/v1beta2/gitrepository/flux-system/flux-system"],
│   on .terraform/modules/flux/flux/main.tf line 59, in resource "kubectl_manifest" "sync":
│   59: resource "kubectl_manifest" "sync" {
│ 
╵
make: *** [Makefile:69: apply] Error 1

## Misc/Random Bits
- https://istio.io/latest/docs/setup/install/helm
- https://knative.dev/docs/install/installing-istio/#installing-istio
- Try litmus with argocd? https://github.com/litmuschaos/chaos-workflows ?
- Deploy knative straight from github? like flux-monitoring.yaml?
- [Running Knative with Istio in a Kind Cluster (old!)](https://www.arthurkoziel.com/running-knative-with-istio-in-kind/)
- [Install Knative using quickstart](https://knative.dev/docs/getting-started/quickstart-install/)
