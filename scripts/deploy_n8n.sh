#!/bin/bash
cd ~/hbrm-test
if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    cp .env.example .env
  else
    echo ".env.example not found, creating basic .env file"
    touch .env
  fi
fi
docker compose -f docker/docker-compose.n8n.yml down || true
docker compose -f docker/docker-compose.n8n.yml pull
docker compose -f docker/docker-compose.n8n.yml up -d
