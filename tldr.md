# From Zero to Secure Infrastructure in Minutes: Automating Hetzner Cloud with Tailscale

*How to build production-ready, secure servers on budget-friendly cloud providers without the complexity*

The cloud infrastructure landscape has a dirty secret: most developers and small teams can't afford the "best practices" recommended by major cloud providers. AWS, Google Cloud, and Azure offer sophisticated security and networking services, but their pricing puts comprehensive solutions out of reach for many projects. Meanwhile, budget-friendly providers like Hetzner Cloud offer excellent hardware at fraction of the cost, but lack the managed security services that make infrastructure deployment straightforward.

This creates a frustrating dilemma. You can either pay premium prices for managed security, or spend weeks configuring VPNs, firewalls, and access controls on cheaper infrastructure. There's a third option: automation that brings enterprise-grade security to budget-friendly cloud providers.

## The Hetzner Advantage

Hetzner Cloud represents the new generation of European cloud providers that prioritize value and performance over marketing hype. A server with 2 vCPUs and 4GB RAM costs around €5.83 per month—roughly half what you'd pay on AWS for equivalent performance. The hardware is modern, the network is fast, and the data centers comply with strict European privacy regulations.

The challenge isn't the infrastructure quality; it's the operational overhead. Unlike major cloud providers, Hetzner doesn't offer managed VPN services, sophisticated identity management, or pre-configured security groups. You're responsible for setting up secure access, managing SSH keys, and configuring firewalls. For a single server, this might be manageable. For multiple servers across different projects, it becomes a significant time sink.

This is where automation becomes essential. Instead of manually configuring each server, you can codify best practices once and apply them consistently. The key is choosing the right tools and approaches that work well with cost-effective providers.

## Tailscale: Enterprise Security Without Enterprise Complexity

Traditional VPN solutions require dedicated servers, complex certificate management, and careful network configuration. Tailscale eliminates this complexity by creating encrypted peer-to-peer connections between devices, based on Wireguard. Each device authenticates independently, and connections are established directly when possible, reducing latency and eliminating single points of failure.

For cloud infrastructure, this approach is transformative. Servers can join a secure network automatically during boot, without exposing SSH ports to the internet. Remote access happens through encrypted channels that integrate with modern identity providers. The entire setup requires minimal configuration and scales effortlessly as you add more servers.

The economic benefits are substantial. Instead of paying for managed VPN services or dedicating server resources to VPN endpoints, you get secure networking as a lightweight service. Tailscale's pricing is reasonable for small teams, and the operational savings from simplified networking often justify the cost.

## Infrastructure as Code: Terraform and OpenTofu

Infrastructure automation has been democratized through tools like Terraform, which allow complex cloud deployments to be expressed in declarative configuration files. What once required custom scripts and deep cloud provider knowledge can now be managed through version-controlled code that works consistently across different cloud providers.

For teams concerned about vendor lock-in and licensing changes, OpenTofu provides a compelling alternative. As a fully compatible, open-source fork of Terraform, OpenTofu maintains the same syntax and functionality while ensuring the tool remains truly open source. This compatibility means existing Terraform configurations work seamlessly with OpenTofu, providing teams the flexibility to choose their preferred tool without rewriting infrastructure code.

The real power of both Terraform and OpenTofu lies in modules—reusable components that encapsulate best practices. A well-designed module can handle the complex orchestration required to deploy secure infrastructure, while exposing simple configuration options for customization. This allows teams to benefit from expert knowledge without becoming experts themselves.

For budget-conscious teams, this approach is particularly valuable. You can achieve the same security and automation standards as larger organizations, without the dedicated DevOps resources typically required to build and maintain such systems, and without concerns about future licensing changes affecting your infrastructure automation.

## Building the Automation

The core challenge in automating secure server deployment is orchestrating multiple moving parts: generating authentication credentials, provisioning servers, configuring firewalls, and setting up secure access. Each step depends on the previous one, and any failure can leave you with partially configured infrastructure.

A Terraform module that handles this orchestration needs to address several key areas:

### Ephemeral Authentication

Traditional server deployment often relies on long-lived SSH keys or passwords embedded in configuration files. This creates persistent security risks and complicates key rotation. A better approach uses ephemeral authentication keys that expire quickly:

```hcl
resource "tailscale_tailnet_key" "server_key" {
  reusable      = false
  ephemeral     = true
  preauthorized = true
  expiry        = 3600
}
```

This generates a one-time authentication key that expires after one hour. The server uses this key to join the Tailscale network during boot, then discards it. Even if an attacker intercepts the key, it's useless after the initial authentication.

### Secure-by-Default Networking

Most firewall configurations start permissive and become restrictive over time, often leaving security gaps. The automation inverts this pattern, starting with minimal permissions:

```hcl
resource "hcloud_firewall" "server_firewall" {
  name = format("%s-firewall", var.server_name)
  
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  
  rule {
    direction = "in"
    protocol  = "udp"
    port      = "41641"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}
```

Notice what's missing: no SSH port 22, no HTTP/HTTPS ports, no database ports. The firewall only allows ICMP for connectivity testing and UDP 41641 for Tailscale connections. All other access happens through Tailscale's encrypted channels.

### Automated Bootstrap Process

The server configuration uses cloud-init to handle the complex setup process automatically:

```yaml
#cloud-config
packages:
  - fail2ban
  - ufw

runcmd:
  - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
  - ['tailscale', 'up', '--auth-key=${tailscale_key}']
  - ['tailscale', 'set', '--ssh']
```

This configuration installs security tools, downloads Tailscale, joins the network using the ephemeral key, and enables Tailscale SSH. The entire process happens automatically during server boot, requiring no manual intervention.

## Real-World Usage Patterns

The automation shines when deploying multiple servers for different purposes. Consider a typical web application stack:

```hcl
module "web_server" {
  source = "github.com/your-org/terraform-hcloud-tailscale-server"
  
  server_name = "web-server"
  server_type = "cx22"
  location    = "fsn1"
  
  runcmd = <<-EOT
    curl -fsSL https://get.docker.com | sh
    docker run -d -p 80:80 nginx
  EOT
}

module "database_server" {
  source = "github.com/your-org/terraform-hcloud-tailscale-server"
  
  server_name = "db-server"
  server_type = "cx32"
  location    = "nbg1"
  
  runcmd = <<-EOT
    apt-get update && apt-get install -y postgresql
    systemctl enable postgresql
  EOT
}
```

Each server joins the same Tailscale network automatically, creating secure connections without complex networking configuration. The web server can connect to the database using Tailscale IPs, eliminating the need for database firewall rules or VPN configuration.

The cost for this two-server setup is approximately €17 per month on Hetzner Cloud—less than what you'd pay for a single equivalent server on major cloud providers. The automation ensures consistent security configuration across all servers, reducing the operational overhead typically associated with managing multiple instances.

## Development Workflow Integration

The automation integrates seamlessly with modern development workflows. Developers can spin up isolated environments for testing without complex networking setup:

```bash
# Create a development environment
terraform workspace new feature-branch
terraform apply -var="server_name=dev-feature-branch"

# Access the server securely
ssh user@dev-feature-branch

# Clean up when done
terraform destroy
terraform workspace delete feature-branch
```

Each environment is automatically secured and accessible to authorized team members. The ephemeral nature of development environments means you're not accumulating security debt from long-lived, poorly configured instances.

## Operational Benefits

The operational advantages extend beyond initial deployment. Server maintenance becomes straightforward when you can access instances securely from anywhere. Debugging production issues doesn't require VPN configuration or firewall rule changes—authorized team members can connect directly through Tailscale.

Monitoring and logging integration is simplified when all servers are part of the same secure network. Monitoring agents can connect to central collection points without exposing additional network ports or configuring complex authentication.

The audit trail is comprehensive. Every connection attempt is logged with user identity and device information, providing much better visibility than traditional SSH logs. This is particularly valuable for compliance requirements or security investigations.

## Cost Analysis

The economic benefits compound over time. Consider a typical startup with 5-10 servers across development, staging, and production environments:

**Traditional Approach (AWS):**
- 10 t3.medium instances: ~€400/month
- VPN server: ~€50/month
- NAT Gateway: ~€45/month
- **Total: ~€495/month**

**Automated Approach (Hetzner + Tailscale):**
- 10 cx22 instances: ~€58/month
- Tailscale team plan: ~€15/month
- **Total: ~€73/month**

The savings are substantial—over €400 per month for a small infrastructure footprint. These savings can fund additional development resources or be reinvested in other areas of the business.

## Security Considerations

The security model provides several advantages over traditional approaches. The elimination of exposed SSH ports removes a common attack vector. The use of ephemeral authentication keys limits the blast radius of any potential compromise. The integration with modern identity providers enables sophisticated access controls without additional infrastructure.

The encrypted nature of all connections provides protection against network-level attacks. This is particularly important when using budget cloud providers that may not offer the same network security guarantees as major providers.

However, the approach does require trust in Tailscale as a service provider. Teams with strict security requirements may prefer self-hosted Wireguard alternatives, though this increases operational complexity significantly. I built a sample project some years ago, check out the [repo](https://github.com/selfscrum/wireguard_network).

## Getting Started

The barrier to entry is deliberately low. You need OpenTofu or Terraform installed, API keys for Hetzner Cloud and Tailscale, and an SSH key uploaded to Hetzner. The entire setup process takes less than 30 minutes, including account creation.

The module handles the complex orchestration automatically, but remains flexible enough for customization. You can add application-specific configuration through the runcmd parameter, deploy across multiple regions, or integrate with existing infrastructure.

The documentation includes examples for common use cases: web applications, database servers, monitoring systems, and development environments. Each example demonstrates best practices while remaining simple enough to understand and modify.

You can immediately use the module in your own OpenTofu project by calling it from the [OpenTofu registry](https://search.opentofu.org/module/sprantic/tailscale-server/hcloud/latest).

## Conclusion

The combination of cost-effective cloud providers, modern networking solutions, and infrastructure automation creates opportunities for building sophisticated infrastructure at reasonable costs. Teams no longer need to choose between security and affordability—they can have both.

The Terraform module for Hetzner Cloud and Tailscale represents this convergence of technologies. It automates the complex orchestration required for secure deployments while maintaining the flexibility needed for diverse use cases. The result is infrastructure that's more secure, more cost-effective, and easier to manage than traditional approaches.

For teams building on budget constraints, this approach provides a path to enterprise-grade infrastructure without enterprise-grade costs. The automation ensures that security best practices are built in from the start, rather than bolted on as an afterthought.

The tools exist today to build secure, automated infrastructure on any cloud provider. The question isn't whether it's possible—it's whether teams will embrace these approaches or continue to accept the false choice between security and affordability.

---

*The complete implementation, including detailed examples and configuration options, is available in the [github project repo](https://github.com/sprantic/terraform-hcloud-tailscale-server). The modular design makes it easy to adapt for specific use cases while maintaining security best practices.*