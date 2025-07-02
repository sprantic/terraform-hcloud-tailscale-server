#
# virtual machine
#

# changes 


data "hcloud_ssh_key" "me" {
  name = var.ssh_keys[0]
}

data "cloudinit_config" "idp" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.yml"
    content_type = "text/cloud-config"
    content      = <<-YAML
      #cloud-config
      hostname: ${var.server_name}
      package_update: true
      package_upgrade: true
      
      # Install basic packages first
      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - gnupg
        - lsb-release
        - git
        - ufw
        - ifupdown

      users:
        - name: ${var.username}
          groups: [sudo]
          shell: /bin/bash
          lock_passwd: true
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh_authorized_keys:
            - ${data.hcloud_ssh_key.me.public_key}

      write_files:
        - path: /tmp/setup-docker.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            set -e
            echo "Setting up Docker repository..."
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            echo "Installing Docker..."
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            systemctl enable docker
            systemctl start docker
            usermod -aG docker ${var.username}
            echo "Docker setup completed"

        - path: /tmp/setup-tailscale.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            set -e
            echo "Installing Tailscale..."
            curl -fsSL https://tailscale.com/install.sh | sh
            echo "Configuring IP forwarding..."
            echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
            echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
            sysctl -p /etc/sysctl.d/99-tailscale.conf
            echo "Starting Tailscale..."
            tailscale up --auth-key=${tailscale_tailnet_key.server_key.key} --hostname=${var.server_name} --timeout=60s
            tailscale set --ssh
            echo "Tailscale setup completed"

      runcmd:
        # Memory settings to avoid JGroups Warnings (do this early)
        - [ bash, -c, "sysctl -w net.core.rmem_max=26214400" ]
        - [ bash, -c, "sysctl -w net.core.wmem_max=1048576" ]

        # Run Docker setup with timeout and error handling
        - [ bash, -c, "timeout 300 /tmp/setup-docker.sh || { echo 'Docker setup failed or timed out'; exit 1; }" ]
        
        # Wait for Docker to be ready with shorter timeout
        - [ bash, -c, "timeout 60 bash -c 'until docker info >/dev/null 2>&1; do echo \"Waiting for Docker daemon...\"; sleep 2; done' || echo 'Docker daemon not ready, continuing...'" ]
        
        # Run Tailscale setup with timeout and error handling
        - [ bash, -c, "timeout 180 /tmp/setup-tailscale.sh || { echo 'Tailscale setup failed or timed out'; exit 1; }" ]
        
        # Setup Docker Compose application if provided
        - [ bash, -c, "echo '${var.docker_compose_yaml != "" ? base64encode(templatefile("${path.module}/scripts/setup-docker-compose.sh", { docker_compose_yaml = var.docker_compose_yaml, project_name = var.docker_compose_project_name != "" ? var.docker_compose_project_name : var.server_name, username = var.username })) : base64encode("#!/bin/bash\necho 'No Docker Compose configuration provided'")}' | base64 -d | bash" ]
        
        # Clean up setup scripts
        - [ rm, -f, /tmp/setup-docker.sh, /tmp/setup-tailscale.sh ]
        
        # Signal completion
        - [ bash, -c, "echo 'Cloud-init setup completed successfully' | tee /var/log/cloud-init-completion.log" ]

      # Ensure cloud-init completes properly
      cloud_final_modules:
        - [scripts-user, always]
        - [final-message, always]

    YAML
  }
}
