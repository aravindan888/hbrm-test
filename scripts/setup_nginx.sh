#!/bin/bash

# Setup NGINX reverse proxy with SSL for n8n
# This script sets up NGINX with Let's Encrypt SSL certificates

set -e

PROJECT_DIR="$HOME/hbrm-test"
cd "$PROJECT_DIR"

# Check if required environment variables are set
if [ -z "$DOMAIN" ]; then
    echo "Error: DOMAIN environment variable is not set"
    echo "Please set DOMAIN=your-domain.com before running this script"
    exit 1
fi

if [ -z "$CERTBOT_EMAIL" ]; then
    echo "Error: CERTBOT_EMAIL environment variable is not set"
    echo "Please set CERTBOT_EMAIL=your-email@domain.com before running this script"
    exit 1
fi

echo "Setting up NGINX reverse proxy for domain: $DOMAIN"

# Create nginx directories if they don't exist
mkdir -p nginx/conf.d
mkdir -p nginx/ssl

# Replace domain placeholder in nginx config
sed "s/\${DOMAIN}/$DOMAIN/g" nginx/conf.d/n8n.conf > nginx/conf.d/n8n.conf.tmp
mv nginx/conf.d/n8n.conf.tmp nginx/conf.d/n8n.conf

echo "Starting NGINX and obtaining SSL certificate..."

# Start nginx without SSL first to get certificate
docker compose -f docker/docker-compose.nginx.yml up -d nginx

# Wait for nginx to be ready
sleep 10

# Obtain SSL certificate
echo "Obtaining SSL certificate from Let's Encrypt..."
docker compose -f docker/docker-compose.nginx.yml run --rm certbot

# Check if certificate was obtained successfully
if [ ! -f "/var/lib/docker/volumes/hbrm-test_certbot_conf/_data/live/$DOMAIN/fullchain.pem" ]; then
    echo "Error: SSL certificate was not obtained successfully"
    echo "Please check your domain DNS settings and try again"
    exit 1
fi

echo "SSL certificate obtained successfully!"

# Restart nginx with SSL configuration
echo "Restarting NGINX with SSL configuration..."
docker compose -f docker/docker-compose.nginx.yml down
docker compose -f docker/docker-compose.nginx.yml up -d

echo "NGINX reverse proxy setup completed!"
echo "Your n8n instance should now be available at: https://$DOMAIN"

# Set up certificate renewal cron job
echo "Setting up automatic certificate renewal..."
(crontab -l 2>/dev/null; echo "0 12 * * * cd $PROJECT_DIR && docker compose -f docker/docker-compose.nginx.yml run --rm certbot renew && docker compose -f docker/docker-compose.nginx.yml restart nginx") | crontab -

echo "Automatic certificate renewal configured!"
echo "Certificates will be renewed daily at 12:00 PM"
