#!/bin/bash
set -e

echo "Setting up Docker Compose application..."

# Create project directory
PROJECT_NAME="${project_name}"
PROJECT_DIR="/opt/docker-compose/$PROJECT_NAME"
mkdir -p "$PROJECT_DIR"
chown ${username}:${username} "$PROJECT_DIR"

# Write Docker Compose file
cat > "$PROJECT_DIR/docker-compose.yml" << 'EOF'
${docker_compose_yaml}
EOF

chown ${username}:${username} "$PROJECT_DIR/docker-compose.yml"

# Wait for Docker to be fully ready
echo "Waiting for Docker daemon to be ready..."
timeout 60 bash -c 'until docker info >/dev/null 2>&1; do echo "Waiting for Docker daemon..."; sleep 2; done' || {
    echo "Docker daemon not ready, but continuing..."
}

# Start the application
echo "Starting Docker Compose application '$PROJECT_NAME'..."
cd "$PROJECT_DIR"
COMPOSE_PROJECT_NAME="$PROJECT_NAME" docker compose up -d

echo "Docker Compose application '$PROJECT_NAME' started successfully"
echo "Application directory: $PROJECT_DIR"