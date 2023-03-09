locals {

  ssh_keys = try({
    private = file(var.id_rsa_ro_path)
    public  = file(var.id_rsa_ro_pub_path)
  }, null)

  additional_keys = zipmap(
    keys(var.additional_keys),
    [for secret in values(var.additional_keys) :
      zipmap(
        keys(secret),
      [for path in values(secret) : file(path)])
  ])
}

resource "kind_cluster" "default" {
  name           = var.kind_cluster_name
  count          = var.kind_cluster_name == null ? 0 : 1
  wait_for_ready = false # true # false likely needed for cilium bootstrap
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      dynamic "extra_mounts" {
        for_each = var.extra_mounts
        content {
          container_path = extra_mounts.value["container_path"]
          host_path      = extra_mounts.value["host_path"]
        }
      }
    }
    #node {
    #  role = "worker"
    #  image = "kindest/node:v1.19.1"
    #}
    # Guess this will work as the creation changes to context?
  }
  // TODO: Should be covered by wait_for_ready?
  provisioner "local-exec" {
    command = "kubectl -n kube-system wait --timeout=180s --for=condition=ready pod -l tier=control-plane"
  }
}

data "http" "metallb_native" {
  count = var.metallb ? 1 : 0
  url   = "https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml"
}

module "metallb_config" {
  count  = var.metallb ? 1 : 0
  source = "github.com/deas/terraform-modules//kind-metallb?ref=main"
}

module "metallb" {
  count            = var.metallb ? 1 : 0
  source           = "../../terraform-modules/metalllb"
  install_manifest = data.http.metallb_native[0].response_body
  config_manifest  = module.metallb_config[0].manifest
  # source = "github.com/deas/terraform-modules//kind-metallb?ref=main"
  providers = {
    # kubernetes    = kubernetes
    kubectl = kubectl
    # kustomization = kustomization
  }

}

# Be careful with this module. It will patch coredns configmap ;)
module "coredns" {
  # version
  # source          = "../../terraform-modules/coredns"
  source = "github.com/deas/terraform-modules//coredns?ref=main"
  hosts  = var.dns_hosts
  count  = var.dns_hosts != null ? 1 : 0
  providers = {
    kubectl = kubectl
  }
}

module "flux" {
  # TODO: Replace kubectl with kustomize in the flux module
  # source             = "github.com/deas/terraform-modules//flux?ref=main"
  source             = "../../terraform-modules/flux"
  namespace          = "flux-system"
  bootstrap_manifest = try(file(var.bootstrap_path), null)
  kustomization_path = var.flux_kustomization_path
  tls_key            = local.ssh_keys
  additional_keys    = local.additional_keys
  providers = {
    kubernetes    = kubernetes
    kubectl       = kubectl
    kustomization = kustomization
  }
}
