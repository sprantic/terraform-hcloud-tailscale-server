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

  server_name        = "my-tailscale-server"
  image              = "ubuntu-22.04"
  server_type        = "cx22"
  location           = "nbg1"
  ssh_keys           = ["my-ssh-key"]
  tailscale_api_key  = var.tailscale_api_key
  tailscale_tailnet  = var.tailscale_tailnet
}
```

### Advanced Example with Custom Commands and Username

```hcl
module "tailscale_server" {
  source = "./path/to/this/module"

  server_name        = "web-server"
  image              = "ubuntu-22.04"
  server_type        = "cx22"
  location           = "fsn1"
  ssh_keys           = ["my-ssh-key"]
  username           = "myuser"  # Custom username instead of default "sprantic"
  tailscale_api_key  = var.tailscale_api_key
  tailscale_tailnet  = var.tailscale_tailnet
  
  # Custom commands to run after Tailscale setup
  runcmd = <<-EOT
    # Install additional software
    apt-get update
    apt-get install -y htop
    
    # Start a web server (Docker is already installed by the module)
    docker run -d -p 80:80 nginx
  EOT
}

output "server_ip" {
  value = module.tailscale_server.ip_address
}
```

### Docker Compose Example

```hcl
module "tailscale_server" {
  source = "./path/to/this/module"

  server_name        = "web-app-server"
  image              = "ubuntu-22.04"
  server_type        = "cx22"
  location           = "fsn1"
  ssh_keys           = ["my-ssh-key"]
  tailscale_api_key  = var.tailscale_api_key
  tailscale_tailnet  = var.tailscale_tailnet
  
  # Docker Compose configuration from local file
  docker_compose_project_name = "webapp"
  docker_compose_yaml = file("${path.module}/docker-compose.yml")
}
```

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    restart: unless-stopped
  
  redis:
    image: redis:alpine
    restart: unless-stopped
    
  app:
    image: node:18-alpine
    working_dir: /app
    ports:
      - "3000:3000"
    depends_on:
      - redis
    restart: unless-stopped
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
| tailscale_api_key | Tailscale API key for device management (required for automatic cleanup on destroy) | `string` | n/a | yes |
| tailscale_tailnet | Tailscale tailnet name (e.g., 'example.com' or 'user@domain.com') | `string` | n/a | yes |
| docker_compose_yaml | Docker Compose YAML configuration to be deployed on the server | `string` | `""` | no |
| docker_compose_project_name | Name for the Docker Compose project (defaults to server name) | `string` | `""` | no |

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
2. **Installs packages**: Basic packages and Docker with Docker Compose
3. **Updates system**: Runs package update and upgrade
4. **Installs Docker**: Sets up Docker CE with proper user permissions
5. **Installs Tailscale**: Downloads and installs the latest Tailscale client
6. **Configures networking**: Enables IP forwarding for potential exit node usage
7. **Joins Tailscale network**: Uses the generated auth key to join
8. **Enables Tailscale SSH**: Allows SSH access through Tailscale
9. **Deploys Docker Compose**: Automatically deploys provided Docker Compose configuration
10. **Runs custom commands**: Executes any commands provided in `runcmd` variable

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
- Automatic device cleanup prevents orphaned entries in Tailscale admin console

## Accessing Your Server

After deployment, you can access your server through Tailscale:

```bash
# SSH via Tailscale (if Tailscale is installed on your local machine)
ssh <username>@<server-tailscale-ip>

# Or use the Tailscale web interface for browser-based SSH
```

## Automatic Tailscale Device Cleanup

This module includes automatic cleanup of Tailscale devices when you run `terraform destroy`. This prevents orphaned device entries from remaining in your Tailscale admin console.

### How it works:
1. When the server is created, it joins Tailscale with a specific hostname matching the `server_name`
2. On `terraform destroy`, a local provisioner automatically:
   - Queries the Tailscale API to find the device by hostname
   - Removes the device from your Tailscale network
   - Cleans up any associated device entries

### Requirements:
- `tailscale_api_key`: A Tailscale API key with device management permissions
- `tailscale_tailnet`: Your Tailscale tailnet identifier

### API Key Permissions:
Your Tailscale API key needs the following permissions:
- **Devices**: Read and Write access to manage device lifecycle

You can create an API key at: https://login.tailscale.com/admin/settings/keys

## Docker Compose Integration

This module includes built-in support for deploying Docker Compose applications automatically during server initialization.

### How it works:
1. **Docker Installation**: Docker and Docker Compose are automatically installed during cloud-init
2. **Configuration Deployment**: Your Docker Compose YAML is written to `/opt/docker-compose/<project-name>/docker-compose.yml`
3. **Automatic Startup**: After Docker is ready, the compose application is automatically started
4. **Project Management**: Uses a configurable project name (defaults to server name) for isolation
5. **Base64 Encoding**: Uses secure base64 encoding to avoid YAML parsing conflicts

### Usage:
```hcl
module "my_server" {
  source = "./path/to/module"
  
  # ... other required variables ...
  
  # Recommended: Use local file
  docker_compose_yaml = file("${path.module}/docker-compose.yml")
  docker_compose_project_name = "myapp"  # Optional, defaults to server_name
}
```

**Alternative: Inline YAML (not recommended for complex configurations):**
```hcl
docker_compose_yaml = <<-EOT
  version: '3.8'
  services:
    web:
      image: nginx:alpine
      ports:
        - "80:80"
EOT
```

### Features:
- **Automatic image pulling**: Images are pulled before starting services
- **Health monitoring**: Shows service status after deployment
- **Error handling**: Includes timeouts and error reporting
- **Project isolation**: Uses Docker Compose project names for isolation

### File locations on server:
- Docker Compose file: `/opt/docker-compose/<project-name>/docker-compose.yml`
- Working directory: `/opt/docker-compose/<project-name>/`
- Logs: Available via `docker compose logs`

### Managing the application:
```bash
# SSH into the server via Tailscale
ssh username@server-tailscale-ip

# Navigate to project directory (replace <project-name> with your project name)
cd /opt/docker-compose/<project-name>

# View running services (with project name)
COMPOSE_PROJECT_NAME=<project-name> docker compose ps

# View logs
COMPOSE_PROJECT_NAME=<project-name> docker compose logs

# Restart services
COMPOSE_PROJECT_NAME=<project-name> docker compose restart

# Update and redeploy
COMPOSE_PROJECT_NAME=<project-name> docker compose pull
COMPOSE_PROJECT_NAME=<project-name> docker compose up -d
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

Created and maintained by the sprantic team.