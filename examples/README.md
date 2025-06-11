# Examples

This directory contains practical examples demonstrating how to use the terraform-hcloud-tailscale-server module.

## Available Examples

### [Basic Example](basic/)
**Purpose**: Simple, minimal setup for getting started quickly.

**What it creates**:
- Single Hetzner Cloud server
- Ubuntu 22.04 with Tailscale
- Basic firewall configuration
- Default user setup

**Best for**: 
- First-time users
- Simple single-server deployments
- Learning the module basics

---

### [Advanced Example](advanced/)
**Purpose**: Comprehensive multi-server setup showcasing advanced features.

**What it creates**:
- Web server with Docker and Nginx
- Database server with PostgreSQL
- Monitoring server with Prometheus and Grafana
- Custom username across all servers
- Service-specific configurations

**Best for**:
- Production-like environments
- Multi-tier applications
- Learning advanced module features
- Understanding Tailscale networking benefits

## Quick Start

1. Choose an example that fits your needs
2. Navigate to the example directory:
   ```bash
   cd basic/  # or advanced/
   ```
3. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
4. Edit `terraform.tfvars` with your actual values
5. Deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Prerequisites

Before running any example, ensure you have:

- **Terraform** >= 0.13 installed
- **Hetzner Cloud account** with API token
- **Tailscale account** with API key
- **SSH key** uploaded to Hetzner Cloud

## Getting Your Credentials

### Hetzner Cloud API Token
1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Select your project
3. Go to "Security" → "API Tokens"
4. Generate a new token with Read & Write permissions

### Tailscale API Key
1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Generate a new API key
3. Note your tailnet name (usually your organization name or email domain)

### SSH Key Setup
1. Generate an SSH key if you don't have one:
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```
2. Upload the public key to Hetzner Cloud:
   - Go to "Security" → "SSH Keys" in Hetzner Cloud Console
   - Add your public key with a memorable name

## Environment Variables (Alternative)

Instead of using `terraform.tfvars`, you can set environment variables:

```bash
export HCLOUD_TOKEN="your-hetzner-cloud-api-token"
export TAILSCALE_API_KEY="your-tailscale-api-key"
export TAILSCALE_TAILNET="your-tailnet-name"
export TF_VAR_ssh_key_name="your-ssh-key-name"
```

## Cost Considerations

### Basic Example
- 1x cx22 server: ~€3.29/month
- **Total**: ~€3.29/month

### Advanced Example
- 1x cx22 server: ~€5.83/month
- 1x cx32 server: ~€11.90/month
- 1x cx22 server: ~€5.83/month
- **Total**: ~€23.56/month

*Prices are approximate and based on Hetzner Cloud pricing as of 2024.*

## Cleanup

To avoid ongoing charges, remember to destroy resources when done:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **"SSH key not found"**: Ensure your SSH key is uploaded to Hetzner Cloud and the name matches
2. **"Invalid API token"**: Check that your Hetzner Cloud token has Read & Write permissions
3. **"Tailscale auth failed"**: Verify your Tailscale API key and tailnet name are correct
4. **"Server not in Tailscale"**: Check cloud-init logs on the server: `sudo cloud-init status --long`

### Getting Help

- Check the main module [README](../README.md) for detailed documentation
- Review individual example READMEs for specific guidance
- Check Terraform and provider documentation for advanced configuration options