# Basic example of using the terraform-hcloud-tailscale-server module

terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.17"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Configure the Tailscale Provider
provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = var.tailscale_tailnet
}

module "basic_tailscale_server" {
  source = "../../"

  server_name       = "basic-tailscale-server"
  image             = "ubuntu-22.04"
  server_type       = "cx22"
  location          = "nbg1"
  ssh_keys          = [var.ssh_key_name]
  tailscale_api_key = var.tailscale_api_key
  tailscale_tailnet = var.tailscale_tailnet
  
  # Optional: Deploy a simple web application
  docker_compose_project_name = "basic-web"
  docker_compose_yaml = file("${path.module}/docker-compose.yml")
}