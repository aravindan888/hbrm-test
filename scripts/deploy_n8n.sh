#!/bin/bash

# Set project directory
PROJECT_DIR="$HOME/hbrm-test"

echo "Deploying n8n from $PROJECT_DIR..."

# Verify project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: Project directory $PROJECT_DIR not found!"
  echo "Please run the 'Setup Server' workflow first to clone the repository."
  exit 1
fi

cd "$PROJECT_DIR"

# Verify we're in the right directory
echo "Current directory: $(pwd)"
echo "Directory contents:"
ls -la

# If .env doesn’t exist, create it from example
if [ ! -f ".env" ]; then
  echo "Creating .env file from .env.example..."
  if [ -f ".env.example" ]; then
    cp .env.example .env
    echo "✅ .env file created from .env.example"
  else
    echo "⚠️  .env.example not found, creating basic .env file"
    cat > .env << EOF
N8N_USER=admin
N8N_PASSWORD=changeme
DOMAIN=n8n.yourdomain.com
CERTBOT_EMAIL=your-email@domain.com
TZ=Asia/Kolkata
EOF
  fi
fi

# Check if Docker Compose is available
DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE_CMD="docker-compose"
  echo "Using docker-compose command"
elif docker compose version &> /dev/null; then
  DOCKER_COMPOSE_CMD="docker compose"
  echo "Using docker compose plugin"
else
  echo "Error: Docker Compose not found!"
  echo "Installing Docker Compose plugin..."
  sudo apt update
  sudo apt install -y docker-compose-plugin
  DOCKER_COMPOSE_CMD="docker compose"
fi

echo "Stopping existing n8n containers..."
$DOCKER_COMPOSE_CMD -f docker/docker-compose.n8n.yml down || true

echo "Pulling latest n8n image..."
$DOCKER_COMPOSE_CMD -f docker/docker-compose.n8n.yml pull

echo "Starting n8n container..."
$DOCKER_COMPOSE_CMD -f docker/docker-compose.n8n.yml up -d

# Verify container is running
echo "Checking container status..."
docker ps | grep n8n || echo "⚠️  n8n container may not be running"

echo "✅ n8n deployment completed!"
echo "🌐 Access n8n at: http://your-server-ip:5678"
echo "📋 Default credentials: admin / changeme (update in .env file)"
