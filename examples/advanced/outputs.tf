output "web_server_ip" {
  description = "The public IPv4 address of the web server"
  value       = module.web_server.ip_address
}

output "database_server_ip" {
  description = "The public IPv4 address of the database server"
  value       = module.database_server.ip_address
}

output "monitoring_server_ip" {
  description = "The public IPv4 address of the monitoring server"
  value       = module.monitoring_server.ip_address
}

output "server_info" {
  description = "Information about all created servers"
  value = {
    web_server = {
      name = "web-server"
      ip   = module.web_server.ip_address
      services = ["nginx (port 80)"]
    }
    database_server = {
      name = "db-server"
      ip   = module.database_server.ip_address
      services = ["postgresql (port 5432)"]
    }
    monitoring_server = {
      name = "monitoring-server"
      ip   = module.monitoring_server.ip_address
      services = ["prometheus (port 9090)", "grafana (port 3000)"]
    }
  }
}

output "access_instructions" {
  description = "Instructions for accessing the services"
  value = <<-EOT
    After deployment, you can access the services via Tailscale:
    
    Web Server:
    - HTTP: http://<web-server-tailscale-ip>
    - SSH: ssh ${var.custom_username}@<web-server-tailscale-ip>
    
    Database Server:
    - PostgreSQL: psql -h <db-server-tailscale-ip> -U myappuser -d myapp
    - SSH: ssh ${var.custom_username}@<db-server-tailscale-ip>
    
    Monitoring Server:
    - Prometheus: http://<monitoring-server-tailscale-ip>:9090
    - Grafana: http://<monitoring-server-tailscale-ip>:3000 (admin/admin123)
    - SSH: ssh ${var.custom_username}@<monitoring-server-tailscale-ip>
    
    Note: Replace <server-tailscale-ip> with the actual Tailscale IP addresses
    visible in your Tailscale admin console.
  EOT
}