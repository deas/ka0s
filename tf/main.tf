# https://github.com/hashicorp/terraform/issues/28580#issuecomment-831263879
terraform {
  required_version = ">= 1.2"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.0.14"
    }
    /*
    github = {
      source  = "integrations/github"
      version = ">= 4.5.2"
    }*/
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
    /* flux = {
      source  = "fluxcd/flux"
      version = ">= 0.0.13"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }*/
  }
}


provider "helm" {
  kubernetes {
    # config_path = kind_cluster.default.kubeconfig
    host                   = kind_cluster.default.endpoint
    client_certificate     = kind_cluster.default.client_certificate
    client_key             = kind_cluster.default.client_key
    cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  }
}

provider "kind" {
}

provider "kubernetes" {
  # config_path = kind_cluster.default.kubeconfig
  # config_context = "kind-flux"
  host                   = kind_cluster.default.endpoint
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
}

provider "kubectl" {
  host                   = kind_cluster.default.endpoint
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  # token                  = data.aws_eks_cluster_auth.main.token
  load_config_file = false
}

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

  metallb_native = [
    for v in data.kubectl_file_documents.metallb_native.documents : {
      data : yamldecode(v)
      content : v
    }
  ]
  metallb_config = [
    for v in data.kubectl_file_documents.metallb_config.documents : {
      data : yamldecode(v)
      content : v
    }
  ]

}

resource "kind_cluster" "default" {
  name           = var.kind_cluster_name
  wait_for_ready = false # true # false likely needed for cilium bootstrap
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    # Cilium
    #networking {
    #  disable_default_cni = true   # do not install kindnet
    #  kube_proxy_mode     = "none" # do not run kube-proxy
    #}

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
  url = "https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml"
}

# TODO: metallb should probably be kicked off via flux as well
data "kubectl_file_documents" "metallb_native" {
  content = data.http.metallb_native.response_body
}

module "metallb_config" {
  source = "github.com/deas/terraform-modules//kind-metallb?ref=main"
}

# TODO: metallb should probably be kicked off via flux as well
data "kubectl_file_documents" "metallb_config" {
  content = module.metallb_config.manifest
}

resource "kubectl_manifest" "metallb_native" {
  for_each  = { for v in local.metallb_native : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  yaml_body = each.value
}

resource "null_resource" "metallb_wait" {
  depends_on = [kubectl_manifest.metallb_native]
  provisioner "local-exec" {
    command = "kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s"
  }
}

resource "kubectl_manifest" "metallb_config" {
  for_each   = { for v in local.metallb_config : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  yaml_body  = each.value
  depends_on = [null_resource.metallb_wait]
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

resource "kubernetes_namespace" "flux-system" {
  metadata {
    name = "flux-system"
  }
}

module "flux" {
  #source    = "../../terraform-modules/flux"
  namespace          = kubernetes_namespace.flux-system.metadata[0].name
  bootstrap_manifest = try(file(var.bootstrap_path), null)
  source             = "github.com/deas/terraform-modules//flux?ref=main"
  flux_install       = file("${var.filename_flux_path}/gotk-components.yaml")
  flux_sync          = file("${var.filename_flux_path}/gotk-sync.yaml")
  tls_key            = local.ssh_keys
  additional_keys    = local.additional_keys
  providers = {
    kubernetes = kubernetes
    kubectl    = kubectl
  }
}