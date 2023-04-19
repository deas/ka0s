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
  # TODO: Whoa! The ultimate mess. Can we do better?
  cilium_spec         = try(yamldecode(file(var.cilium_helmrelease_path))["spec"], null)
  cilium_version      = try(local.cilium_spec["chart"]["spec"]["version"], null)
  cilium_release_name = try(local.cilium_spec["releaseName"], null)
  cilium_values = try(yamlencode(merge(
    local.cilium_spec["values"],
    {
      "hubble" = {
        "metrics" = { "serviceMonitor" = { "enabled" = false } },
        "relay"   = { "prometheus" = { "serviceMonitor" = { "enabled" = false } } }
      }
    }
  )), null)
  # We want kind to fully play with kube-prometheus
  kubeadmin_patches = compact([<<EOF
kind: ClusterConfiguration
# configure controller-manager bind address
controllerManager:
  extraArgs:
    bind-address: 0.0.0.0 #Disable localhost binding
#    secure-port: "0"      #Disable the https 
#    port: "10257"         #Enable http on port 10257
# configure etcd metrics listen address
etcd:
  local:
    extraArgs:
      listen-metrics-urls: http://0.0.0.0:2381
# configure scheduler bind address
scheduler:
  extraArgs:
    bind-address: 0.0.0.0  #Disable localhost binding
#    secure-port: "0"       #Disable the https
#    port: "10259"          #Enable http on port 10259
EOF
    ,
    <<EOF
kind: KubeProxyConfiguration
# configure proxy metrics bind address
metricsBindAddress: 0.0.0.0
EOF
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
      role  = "control-plane"
      image = var.kind_cluster_image
      dynamic "extra_mounts" {
        for_each = var.extra_mounts
        content {
          container_path = extra_mounts.value["container_path"]
          host_path      = extra_mounts.value["host_path"]
        }
      }
      # Does NOT work with metallb loadbalancers consuming IPs from Docker IPAM. Only with kind container IP
      # The default range is indeed 30000-32767 but it can be changed by setting the --service-node-port-range 
      dynamic "extra_port_mappings" {
        for_each = var.extra_port_mappings
        content {
          container_port = extra_port_mappings.value["container_port"]
          host_port      = extra_port_mappings.value["host_port"]
        }
        # optional: set the bind address on the host
        # 0.0.0.0 is the current default
        # listen_address = "127.0.0.1"
        # optional: set the protocol to one of TCP, UDP, SCTP.
        # TCP is the default
        # protocol =  "TCP"
      }
      kubeadm_config_patches = local.kubeadmin_patches
    }
    #node {
    #  role = "worker"
    #  image = "kindest/node:v1.19.1"
    #}
    networking {
      disable_default_cni = var.cilium_helmrelease_path != null                       # do not install kindnet for cilium
      kube_proxy_mode     = var.cilium_helmrelease_path != null ? "none" : "iptables" # do not run kube-proxy for cilium
    }
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
  count  = var.metallb ? 1 : 0
  source = "github.com/deas/terraform-modules//metallb?ref=main"
  # source           = "../../terraform-modules/metallb"
  install_manifest = data.http.metallb_native[0].response_body
  config_manifest  = module.metallb_config[0].manifest
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

# Bare minimum to get CNI up here (Won't work via flux)
resource "helm_release" "cilium" {
  count      = var.cilium_helmrelease_path != null ? 1 : 0 # var.cilium_version != null ? 1 : 0
  name       = local.cilium_release_name
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = local.cilium_version # var.cilium_version
  namespace  = "kube-system"
  values     = [local.cilium_values]
  # file("../infrastructure/lib/config/cilium/values-cilium.yaml")]
  # values     = [file("cilium-values.yaml")]
}

module "flux" {
  # TODO: Replace kubectl with kustomize in the flux module
  source = "github.com/deas/terraform-modules//flux?ref=main"
  # source             = "../../terraform-modules/flux"
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
