variable "kind_cluster_name" {
  type        = string
  description = "Cluster name"
  default     = null
  # default     = "ka0s"
}

variable "kind_cluster_image" {
  type    = string
  default = null
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

variable "metallb" {
  type    = bool
  default = true
}
