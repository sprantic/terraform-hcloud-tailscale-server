resource "tailscale_tailnet_key" "server_key" {
  reusable      = false
  ephemeral     = true
  preauthorized = true
  expiry        = 3600
  description   = substr(format("Key for %s", var.server_name), 0, 50)
}

resource "hcloud_server" "server" {
  name         = var.server_name
  image        = var.image
  server_type  = var.server_type
  location     = var.location
  firewall_ids = [hcloud_firewall.server_firewall.id]
  # the cloud init file consists of the "management part" which is coming from the module and the "runcmd part" which is coming from the module user.
  ssh_keys     = [data.hcloud_ssh_key.me.id]
  user_data  = data.cloudinit_config.idp.rendered
}

# Separate resource for Tailscale device cleanup
resource "null_resource" "tailscale_cleanup" {
  # This resource depends on the server existing
  depends_on = [hcloud_server.server]
  
  # Trigger recreation when server changes and store credentials
  triggers = {
    server_id = hcloud_server.server.id
    server_name = var.server_name
    api_key = var.tailscale_api_key
    tailnet = var.tailscale_tailnet
  }

  # Cleanup provisioner that uses self.triggers for all values
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Wait a moment for any pending operations
      sleep 5
      
      # Get the device ID using Tailscale API
      DEVICE_ID=$(curl -s -H "Authorization: Bearer ${self.triggers.api_key}" \
        "https://api.tailscale.com/api/v2/tailnet/${self.triggers.tailnet}/devices" | \
        jq -r '.devices[] | select(.hostname == "${self.triggers.server_name}") | .id')
      
      # Delete the device if found
      if [ ! -z "$DEVICE_ID" ] && [ "$DEVICE_ID" != "null" ]; then
        echo "Removing Tailscale device: ${self.triggers.server_name} (ID: $DEVICE_ID)"
        curl -X DELETE -H "Authorization: Bearer ${self.triggers.api_key}" \
          "https://api.tailscale.com/api/v2/device/$DEVICE_ID"
        echo "Tailscale device removed successfully"
      else
        echo "Tailscale device ${self.triggers.server_name} not found or already removed"
      fi
    EOT
  }
}

# we don't need port 22 due to tailscale
resource "hcloud_firewall" "server_firewall" {
  name = format("%s-firewall", var.server_name)
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "udp"
    port      = "41641"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "out"
    protocol  = "udp"
    port      = "3478"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # we can skip that last rule later if everything runs stable
  rule {
    direction    = "out"
    protocol     = "tcp"
    destination_ips = ["0.0.0.0/0"]
    port         = "1-65535"
  }

}

