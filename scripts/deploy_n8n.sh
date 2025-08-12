#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "--- Starting n8n Deployment Script ---"
echo "Current user: $(whoami)"
echo "User groups: $(groups)"
echo "Current directory: $(pwd)"

cd ~/hbrm-test
echo "Changed directory to $(pwd)"

if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    echo "Creating .env from .env.example"
    cp .env.example .env
  else
    echo ".env.example not found, creating basic .env file"
    touch .env
  fi
fi

echo "Bringing down existing n8n containers..."
# The || true is good here to prevent failure if containers don't exist
docker compose -f docker/docker-compose.n8n.yml down || true

echo "Pulling latest n8n images..."
docker compose -f docker/docker-compose.n8n.yml pull

echo "Starting new n8n containers..."
docker compose -f docker/docker-compose.n8n.yml up -d

echo "--- Deployment Script Finished Successfully ---"
