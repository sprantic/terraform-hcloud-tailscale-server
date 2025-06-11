Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bitspra
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
users:
    - name: ${username}
      groups: users, admin, sudo, adm
      sudo: ALL=(ALL) NOPASSWD:ALL
      shell: /bin/bash
packages:
    - fail2ban
    - ufw
    - ifupdown

package_update: true
package_upgrade: true
runcmd:
    # One-command install, from https://tailscale.com/download/
    - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
    # Set sysctl settings for IP forwarding (useful when configuring an exit node)
    - ['sh', '-c', "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf" ]
    # Generate an auth key from your Admin console
    # https://login.tailscale.com/admin/settings/keys
    # and replace the placeholder below
    - ['tailscale', 'up', '--auth-key=${tailscale_key}']
    # (Optional) Include this line to make this node available over Tailscale SSH
    - ['tailscale', 'set', '--ssh']
    # (Optional) Include this line to configure this machine as an exit node
    # - ['tailscale', 'set', '--advertise-exit-node']

cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
# This script is meant to be run in the User Data of each Instance while it's booting. 
set -e
