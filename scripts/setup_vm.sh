#!/bin/bash

# Set project directory name
PROJECT_DIR="hbrm-test"

# Clone repo if not present
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Cloning repository..."
  # Use GitHub token for authentication if repository is private
  if [ -n "$GITHUB_TOKEN" ]; then
    git clone https://$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY $PROJECT_DIR
  else
    # For public repositories, use HTTPS without token
    git clone https://github.com/$GITHUB_REPOSITORY $PROJECT_DIR
  fi
else
  echo "Repository already exists, pulling latest changes..."
  cd $PROJECT_DIR && git pull origin main && cd ..
fi

cd $PROJECT_DIR

# Make scripts executable
chmod +x scripts/*.sh

# Create the deploy_n8n.sh script
cat > scripts/deploy_n8n.sh << 'DEPLOY_SCRIPT_EOF'
#!/bin/bash

# Bulletproof n8n Deployment Script
set -e  # Exit on any error

echo "🚀 Starting n8n deployment process..."

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Determine project directory
PROJECT_DIR="$HOME/hbrm-test"
OLD_PROJECT_DIR="$HOME/n8n-hbrm"

log "Checking project directories..."

# Remove old directory if it exists
if [ -d "$OLD_PROJECT_DIR" ]; then
    log "⚠️  Removing old project directory: $OLD_PROJECT_DIR"
    rm -rf "$OLD_PROJECT_DIR"
fi

# Verify correct project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    log "❌ Project directory $PROJECT_DIR not found!"
    log "Available directories in home:"
    ls -la "$HOME/" | grep -E "(hbrm|n8n)" || log "No project directories found"
    log "Please run the 'Setup Server' workflow first."
    exit 1
fi

log "✅ Project directory found: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Verify we're in the right directory
log "📁 Current directory: $(pwd)"

# Verify required files exist
if [ ! -f "docker/docker-compose.n8n.yml" ]; then
    log "❌ Docker Compose file not found: docker/docker-compose.n8n.yml"
    log "Available files in docker directory:"
    ls -la docker/ || log "Docker directory not found"
    exit 1
fi

log "✅ Docker Compose file found"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    log "📝 Creating .env file..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        log "✅ .env file created from .env.example"
    else
        log "⚠️  .env.example not found, creating basic .env file"
        cat > .env << 'ENVEOF'
N8N_USER=admin
N8N_PASSWORD=changeme
DOMAIN=n8n.yourdomain.com
CERTBOT_EMAIL=your-email@domain.com
TZ=Asia/Kolkata
ENVEOF
        log "✅ Basic .env file created"
    fi
else
    log "✅ .env file already exists"
fi

# Check Docker installation
if ! command_exists docker; then
    log "❌ Docker not found! Installing Docker..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker "$USER"
    log "✅ Docker installed"
fi

# Check Docker Compose availability
DOCKER_COMPOSE_CMD=""
if command_exists docker-compose; then
    DOCKER_COMPOSE_CMD="docker-compose"
    log "✅ Using docker-compose command"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    log "✅ Using docker compose plugin"
else
    log "⚠️  Docker Compose not found! Installing..."
    sudo apt update
    sudo apt install -y docker-compose-plugin
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
        log "✅ Docker Compose plugin installed"
    else
        log "❌ Failed to install Docker Compose"
        exit 1
    fi
fi

# Ensure Docker service is running
if ! sudo systemctl is-active docker &> /dev/null; then
    log "🔄 Starting Docker service..."
    sudo systemctl start docker
fi

log "🛑 Stopping existing n8n containers..."
$DOCKER_COMPOSE_CMD -f docker/docker-compose.n8n.yml down || true

log "📥 Pulling latest n8n image..."
$DOCKER_COMPOSE_CMD -f docker/docker-compose.n8n.yml pull

log "🚀 Starting n8n container..."
$DOCKER_COMPOSE_CMD -f docker/docker-compose.n8n.yml up -d

# Wait for container to start
log "⏳ Waiting for container to start..."
sleep 10

# Verify container is running
log "🔍 Checking container status..."
if docker ps | grep -q n8n; then
    log "✅ n8n container is running successfully!"

    # Get container details
    CONTAINER_ID=$(docker ps | grep n8n | awk '{print $1}')
    log "📋 Container ID: $CONTAINER_ID"

    # Show container logs (last 5 lines)
    log "📄 Recent container logs:"
    docker logs --tail 5 "$CONTAINER_ID" || true

else
    log "❌ n8n container is not running!"
    log "🔍 Checking all containers:"
    docker ps -a

    log "📄 Checking Docker Compose logs:"
    $DOCKER_COMPOSE_CMD -f docker/docker-compose.n8n.yml logs || true

    exit 1
fi

# Get server IP for access URL
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "your-server-ip")

log "🎉 n8n deployment completed successfully!"
log "🌐 Access n8n at: http://$SERVER_IP:5678"
log "🔐 Default credentials: admin / changeme"
log "⚙️  To change credentials, edit the .env file and restart the container"
log "🔄 To restart: $DOCKER_COMPOSE_CMD -f docker/docker-compose.n8n.yml restart"

echo ""
echo "=== DEPLOYMENT SUMMARY ==="
echo "✅ Project Directory: $PROJECT_DIR"
echo "✅ Docker Compose: $DOCKER_COMPOSE_CMD"
echo "✅ Container Status: Running"
echo "✅ Access URL: http://$SERVER_IP:5678"
echo "✅ Credentials: admin / changeme"
echo "=========================="
DEPLOY_SCRIPT_EOF

chmod +x scripts/deploy_n8n.sh

echo "VM setup completed successfully!"
