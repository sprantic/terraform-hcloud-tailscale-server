# Advanced Example

This example demonstrates advanced usage of the terraform-hcloud-tailscale-server module, including:

- Multiple servers with different purposes
- Custom username configuration
- Complex application deployments
- Service-specific configurations

## What this example creates

### Web Server (`web-server`)
- **Location**: Falkenstein (fsn1)
- **Type**: cx22 (2 vCPU, 8 GB RAM)
- **Services**: 
  - Docker
  - Nginx web server (port 80)
- **Custom**: Uses custom username

### Database Server (`db-server`)
- **Location**: Nuremberg (nbg1)
- **Type**: cx32 (2 vCPU, 16 GB RAM)
- **Services**:
  - PostgreSQL database server
  - Database: `myapp`
  - User: `myappuser`
- **Custom**: Configured for Tailscale network access

### Monitoring Server (`monitoring-server`)
- **Location**: Helsinki (hel1)
- **Type**: cx22 (2 vCPU, 8 GB RAM)
- **Services**:
  - Prometheus (port 9090)
  - Grafana (port 3000)
- **Custom**: Docker Compose setup

## Usage

1. Copy the example terraform.tfvars file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your values:

```hcl
hcloud_token      = "your-hetzner-cloud-api-token"
tailscale_api_key = "your-tailscale-api-key"
tailscale_tailnet = "your-tailnet-name"
ssh_key_name      = "your-ssh-key-name"
custom_username   = "devops"  # or any username you prefer
```

3. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

## Accessing Services

After deployment, all services are accessible via Tailscale network:

### Web Server
```bash
# Access the web page
curl http://<web-server-tailscale-ip>

# SSH access
ssh devops@<web-server-tailscale-ip>
```

### Database Server
```bash
# Connect to PostgreSQL
psql -h <db-server-tailscale-ip> -U myappuser -d myapp

# SSH access
ssh devops@<db-server-tailscale-ip>
```

### Monitoring Server
```bash
# Access Prometheus
open http://<monitoring-server-tailscale-ip>:9090

# Access Grafana (admin/admin123)
open http://<monitoring-server-tailscale-ip>:3000

# SSH access
ssh devops@<monitoring-server-tailscale-ip>
```

## Architecture Benefits

This setup demonstrates several advantages:

1. **Secure Communication**: All inter-service communication happens over Tailscale's encrypted network
2. **No Public Exposure**: Database and monitoring services are not exposed to the public internet
3. **Simplified Networking**: No need to configure complex firewall rules between services
4. **Easy Access**: Developers can access all services directly via Tailscale
5. **Scalable**: Easy to add more services to the same network

## Customization

You can modify this example to:

- Change server types and locations
- Add more services (Redis, Elasticsearch, etc.)
- Modify the custom commands for different software stacks
- Use different usernames per server
- Add additional firewall rules if needed

## Clean up

To destroy all resources:

```bash
terraform destroy
```

## Security Notes

- PostgreSQL is configured to accept connections from Tailscale network (100.64.0.0/10)
- Grafana uses a default password - change it after first login
- All services use Tailscale SSH instead of traditional SSH
- Consider using Terraform variables for sensitive data like database passwords