output "server_ip_address" {
  description = "The public IPv4 address of the created server"
  value       = module.basic_tailscale_server.ip_address
}

output "server_name" {
  description = "The name of the created server"
  value       = "basic-tailscale-server"
}