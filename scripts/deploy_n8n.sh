#!/bin/bash

# Set project directory
PROJECT_DIR="$HOME/hbrm-test"

echo "Deploying n8n from $PROJECT_DIR..."

cd "$PROJECT_DIR"

# If .env doesn’t exist, create it from example
if [ ! -f ".env" ]; then
  echo "Creating .env file from .env.example..."
  cp .env.example .env
  echo "Please update .env file with your credentials before running n8n"
fi

echo "Stopping existing n8n containers..."
docker compose -f docker/docker-compose.n8n.yml down || true

echo "Pulling latest n8n image..."
docker compose -f docker/docker-compose.n8n.yml pull

echo "Starting n8n container..."
docker compose -f docker/docker-compose.n8n.yml up -d

echo "n8n deployment completed!"
echo "Access n8n at: http://your-server-ip:5678"
