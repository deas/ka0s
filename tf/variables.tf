variable "kind_cluster_name" {
  type        = string
  description = "Cluster name"
  default     = null
  # default     = "ka0s"
}

variable "kind_cluster_image" {
  type    = string
  default = "kindest/node:v1.25.8"
}

variable "id_rsa_ro_path" {
  type    = string
  default = null
}

variable "id_rsa_ro_pub_path" {
  type    = string
  default = null
}

variable "additional_keys" {
  type    = map(any)
  default = {}
}

variable "bootstrap_path" {
  type        = string
  default     = null
  description = "Bootstrap path to yaml we apply before flux"
}

variable "flux_kustomization_path" {
  type    = string
  default = "../clusters/local/flux-system"
}

variable "dns_hosts" {
  type    = map(string)
  default = null
}

variable "extra_mounts" {
  type    = list(map(string))
  default = []
}

variable "extra_port_mappings" {
  type = list(map(string))
  default = [
    /*
    {
      container_port = 30080
      host_port      = 3000 # Grafana
    },
    {
      container_port = 30180
      host_port      = 3100 # Loki
    },
    {
      container_port = 30280
      host_port      = 9411 # Zipkin
    },
    {
      container_port = 30380
      host_port      = 10080 # Istio-Ingress
    },
    {
      container_port = 30480
      host_port      = 10180 # Litmus-Server
    },
    {
      container_port = 30580
      host_port      = 10280 # Hubble-UI
    }
*/
  ]
}

variable "cilium_helmrelease_path" {
  type    = string
  default = "../infrastructure/lib/config/cilium/release-cilium.yaml"
}

variable "metallb" {
  type    = bool
  default = true
}
