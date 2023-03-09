# https://github.com/hashicorp/terraform/issues/28580#issuecomment-831263879
terraform {
  required_version = ">= 1.2"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.0.14"
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
    kustomization = {
      source  = "kbst/kustomization"
      version = ">= 0.9.0"
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