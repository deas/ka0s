variable "kind_cluster_name" {
  type        = string
  description = "Cluster name"
  default     = "ka0s"
}

variable "target_path" {
  type        = string
  description = "flux sync target path"
}

variable "id_rsa_fluxbot_ro_path" {
  type = string
}

variable "id_rsa_fluxbot_ro_pub_path" {
  type = string
}

variable "additional_keys" {
  type    = map(any)
  default = {}
}

variable "filename_flux_path" {
  type    = string
  default = "../simple/clusters/local/flux-system"
}

variable "cluster" {
  type = string
}
