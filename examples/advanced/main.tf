# Advanced example of using the terraform-hcloud-tailscale-server module
# This example shows custom username, custom commands, and multiple servers

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

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Configure the Tailscale Provider
provider "tailscale" {
  api_key = var.tailscale_api_key
#  tailnet = var.tailscale_tailnet
}

# Web server with Docker and custom username
module "web_server" {
  source = "../../"

  server_name = "web-server"
  image       = "ubuntu-22.04"
  server_type = "cx22"
  location    = "fsn1"
  ssh_keys    = [var.ssh_key_name]
  username    = var.custom_username

  # Install Docker and run a web server
  runcmd = <<-EOT
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker ${var.custom_username}
    
    # Start nginx web server
    docker run -d --name nginx-server -p 80:80 nginx:latest
    
    # Create a simple index page
    docker exec nginx-server sh -c 'echo "<h1>Hello from Tailscale Server!</h1><p>Server: web-server</p>" > /usr/share/nginx/html/index.html'
  EOT
}

# Database server with PostgreSQL
module "database_server" {
  source = "../../"

  server_name = "db-server"
  image       = "ubuntu-22.04"
  server_type = "cx32"
  location    = "nbg1"
  ssh_keys    = [var.ssh_key_name]
  username    = var.custom_username

  # Install PostgreSQL
  runcmd = <<-EOT
    # Install PostgreSQL
    apt-get update
    apt-get install -y postgresql postgresql-contrib
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Create a database and user
    sudo -u postgres createdb myapp
    sudo -u postgres psql -c "CREATE USER myappuser WITH PASSWORD 'secure_password';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE myapp TO myappuser;"
    
    # Configure PostgreSQL to listen on all addresses (for Tailscale network)
    echo "listen_addresses = '*'" >> /etc/postgresql/*/main/postgresql.conf
    echo "host all all 100.64.0.0/10 md5" >> /etc/postgresql/*/main/pg_hba.conf
    
    # Restart PostgreSQL
    systemctl restart postgresql
  EOT
}

# Monitoring server with Prometheus and Grafana
module "monitoring_server" {
  source = "../../"

  server_name = "monitoring-server"
  image       = "ubuntu-22.04"
  server_type = "cx22"
  location    = "hel1"
  ssh_keys    = [var.ssh_key_name]
  username    = var.custom_username

  # Install Docker and run monitoring stack
  runcmd = <<-EOT
    # Install Docker and Docker Compose
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker ${var.custom_username}
    
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Create monitoring directory
    mkdir -p /opt/monitoring
    cd /opt/monitoring
    
    # Create docker-compose.yml for Prometheus and Grafana
    cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    restart: unless-stopped
    
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    restart: unless-stopped
EOF
    
    # Start the monitoring stack
    docker-compose up -d
  EOT
}