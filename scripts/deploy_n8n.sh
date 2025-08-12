#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "--- Running n8n deployment script ---"

# The script assumes it's being run from the project root directory
if [ ! -f "docker/docker-compose.n8n.yml" ]; then
    echo "Error: Must be run from the project root."
    exit 1
fi

if [ ! -f ".env" ]; then
  echo "INFO: .env file not found. Copying from .env.example"
  cp .env.example .env
fi

# Docker commands should now work without sudo
echo "Pulling latest images..."
docker compose -f docker/docker-compose.n8n.yml pull

echo "Restarting services..."
docker compose -f docker/docker-compose.n8n.yml up -d --remove-orphans

echo "--- Deployment script finished. ---"
