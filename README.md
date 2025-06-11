# Terraform Hetzner Cloud Tailscale Server Module

A Terraform module to create a Hetzner Cloud virtual machine that automatically joins a Tailscale network with secure firewall configuration.

## Features

- 🚀 **Automated Tailscale Setup**: Automatically installs and configures Tailscale on server boot
- 🔒 **Secure Firewall**: Pre-configured firewall rules optimized for Tailscale connectivity
- 🔑 **SSH-less Access**: Uses Tailscale SSH for secure remote access (no need for port 22)
- ⚡ **Cloud-init Integration**: Supports custom user commands via cloud-init
- 🛡️ **Security Hardening**: Includes fail2ban and ufw packages for additional security

## Architecture

This module creates:
- A Hetzner Cloud server with specified configuration
- A Tailscale auth key (ephemeral, preauthorized)
- A firewall with Tailscale-optimized rules
- Cloud-init configuration for automatic Tailscale setup

## Prerequisites

- Terraform >= 0.13
- Hetzner Cloud API token
- Tailscale API key with appropriate permissions
- SSH key uploaded to Hetzner Cloud

## Required Providers

```hcl
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
```

## Usage

### Basic Example

```hcl
module "tailscale_server" {
  source = "./path/to/this/module"

  server_name = "my-tailscale-server"
  image       = "ubuntu-22.04"
  server_type = "cx22"
  location    = "nbg1"
  ssh_keys    = ["my-ssh-key"]
}
```

### Advanced Example with Custom Commands and Username

```hcl
module "tailscale_server" {
  source = "./path/to/this/module"

  server_name = "web-server"
  image       = "ubuntu-22.04"
  server_type = "cx22"
  location    = "fsn1"
  ssh_keys    = ["my-ssh-key"]
  username    = "myuser"  # Custom username instead of default "sprantic"
  
  # Custom commands to run after Tailscale setup
  runcmd = <<-EOT
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    
    # Start a web server
    docker run -d -p 80:80 nginx
  EOT
}

output "server_ip" {
  value = module.tailscale_server.ip_address
}
```

## Examples

This module includes several examples to help you get started:

### [Basic Example](examples/basic/)
A simple example showing basic usage with minimal configuration:
- Single server deployment
- Default settings
- Basic Tailscale integration

### [Advanced Example](examples/advanced/)
A comprehensive example demonstrating advanced features:
- Multiple servers (web, database, monitoring)
- Custom username configuration
- Complex application deployments (Docker, PostgreSQL, Prometheus, Grafana)
- Service-specific configurations

To use any example:
```bash
cd examples/basic  # or examples/advanced
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| server_name | Name of the server | `string` | n/a | yes |
| image | The image ID that will be used to create the instance | `string` | n/a | yes |
| server_type | The Hetzner server type that will be used to create the instance | `string` | n/a | yes |
| location | The Hetzner location code that will be used to create the instance | `string` | n/a | yes |
| ssh_keys | The public key that will be used to check ssh access | `list(string)` | n/a | yes |
| runcmd | The runcommand part of the cloud_init script | `string` | `""` | no |
| username | The username for the created user on the server | `string` | `"sprantic"` | no |

### Available Hetzner Cloud Locations

- `ash` - Ashburn, VA
- `fsn1` - Falkenstein, Germany
- `hel1` - Helsinki, Finland
- `nbg1` - Nuremberg, Germany
- `hil` - Hillsboro, OR

### Common Server Types

- `cx22` - 2 vCPU, 4 GB RAM

## Outputs

| Name | Description |
|------|-------------|
| ip_address | The public IPv4 address of the created server |

## Firewall Configuration

The module creates a firewall with the following rules:

### Inbound Rules
- **ICMP**: Allow ping from anywhere
- **UDP 41641**: Tailscale default port for peer-to-peer connections

### Outbound Rules
- **UDP 3478**: STUN protocol for NAT traversal
- **TCP 1-65535**: All outbound TCP traffic (temporary rule for stability)

> **Note**: SSH (port 22) is intentionally blocked as Tailscale SSH is used instead.

## Cloud-init Configuration

The module uses a multi-part cloud-init configuration that:

1. **Creates a user**: Configurable username (default: `sprantic`) with sudo privileges
2. **Installs packages**: fail2ban, ufw, ifupdown
3. **Updates system**: Runs package update and upgrade
4. **Installs Tailscale**: Downloads and installs the latest Tailscale client
5. **Configures networking**: Enables IP forwarding for potential exit node usage
6. **Joins Tailscale network**: Uses the generated auth key to join
7. **Enables Tailscale SSH**: Allows SSH access through Tailscale
8. **Runs custom commands**: Executes any commands provided in `runcmd` variable

## Environment Variables

Set the following environment variables for provider authentication:

```bash
# Hetzner Cloud
export HCLOUD_TOKEN="your-hetzner-cloud-api-token"

# Tailscale
export TAILSCALE_API_KEY="your-tailscale-api-key"
export TAILSCALE_TAILNET="your-tailnet-name"
```

## Security Considerations

- The server is configured to use Tailscale SSH instead of traditional SSH
- Firewall rules are restrictive and only allow necessary Tailscale traffic
- fail2ban is installed for additional protection against brute force attacks
- The Tailscale auth key is ephemeral and expires after 1 hour
- All packages are updated during initial setup

## Accessing Your Server

After deployment, you can access your server through Tailscale:

```bash
# SSH via Tailscale (if Tailscale is installed on your local machine)
ssh <username>@<server-tailscale-ip>

# Or use the Tailscale web interface for browser-based SSH
```

## Troubleshooting

### Server not appearing in Tailscale admin console
- Check cloud-init logs: `sudo cloud-init status --long`
- Verify Tailscale service: `sudo systemctl status tailscaled`

### Cannot connect via Tailscale SSH
- Ensure Tailscale is running on your local machine
- Check if the server is online in Tailscale admin console
- Verify SSH is enabled: `tailscale status --json | jq .Self.HostName`

### Custom runcmd not executing
- Check cloud-init logs: `sudo cat /var/log/cloud-init-output.log`
- Verify script syntax and permissions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This module is released under the MIT License. See LICENSE file for details.

## Authors

Created and maintained by the Sprantic team.