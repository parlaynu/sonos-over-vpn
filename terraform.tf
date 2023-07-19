terraform {  
  required_version = ">= 1.3.2"
  required_providers {
    wireguard = {
      source = "ojford/wireguard"
      version = "0.2.1+1"
    }
  }
}


provider "wireguard" {}

