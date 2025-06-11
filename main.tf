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
  ssh_keys     = var.ssh_keys
  firewall_ids = [hcloud_firewall.server_firewall.id]
  # the cloud init file consists of the "management part" which is coming from the module and the "runcmd part" which is coming from the module user.
  user_data = <<EOT
${templatefile(format("%s/user_data.cc", path.module), {
    tailscale_key = tailscale_tailnet_key.server_key.key,
    username = var.username,
  })}
${var.runcmd}
EOT
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

