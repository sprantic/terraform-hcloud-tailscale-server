# Basic Example

This example demonstrates the basic usage of the terraform-hcloud-tailscale-server module.

## What this example creates

- A single Hetzner Cloud server with Ubuntu 22.04
- Automatic Tailscale installation and configuration
- Basic firewall rules for Tailscale connectivity
- A user account with sudo privileges

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your actual values:

```hcl
hcloud_token      = "your-hetzner-cloud-api-token"
tailscale_api_key = "your-tailscale-api-key"
tailscale_tailnet = "your-tailnet-name"
ssh_key_name      = "your-ssh-key-name"
```

3. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

## Requirements

- Terraform >= 0.13
- Hetzner Cloud API token
- Tailscale API key
- SSH key uploaded to Hetzner Cloud

## Outputs

- `server_ip_address`: The public IPv4 address of the created server
- `server_name`: The name of the created server

## Clean up

To destroy the resources:

```bash
terraform destroy