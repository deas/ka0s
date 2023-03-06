variable "kind_cluster_name" {
  type        = string
  description = "Cluster name"
  default     = "ka0s"
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

variable "filename_flux_path" {
  type    = string
  default = "../clusters/local/flux-system"
}

variable "dns_hosts" {
  type    = map(string)
  default = null
}