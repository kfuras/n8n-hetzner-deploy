terraform {
  required_providers {
    hcloud = {
      source  = "opentofu/hcloud"
      version = "~> 1.50"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "hcloud" {
  token = var.hcloud_token
}