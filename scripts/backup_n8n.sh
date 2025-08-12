#!/bin/bash

# Backup n8n data to Google Drive using rclone
# This script creates a backup of the n8n data directory and uploads it to Google Drive
# Keeps the last 30 backups with automatic rotation

set -e

PROJECT_DIR="$HOME/hbrm-test"
BACKUP_DIR="$HOME/n8n-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="n8n_backup_$TIMESTAMP"
RCLONE_REMOTE="gdrive"
GDRIVE_BACKUP_PATH="n8n-backups"

echo "Starting n8n backup process..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "Installing rclone..."
    curl https://rclone.org/install.sh | sudo bash
fi

# Check if rclone is configured for Google Drive
if ! rclone listremotes | grep -q "^${RCLONE_REMOTE}:$"; then
    echo "Error: rclone is not configured for Google Drive"
    echo "Please run 'rclone config' to set up Google Drive remote named '${RCLONE_REMOTE}'"
    echo "Or set the RCLONE_CONFIG_GDRIVE_* environment variables"
    exit 1
fi

# Stop n8n container temporarily for consistent backup
echo "Stopping n8n container for backup..."
cd "$PROJECT_DIR"
docker compose -f docker/docker-compose.n8n.yml stop n8n || docker compose -f docker/docker-compose.nginx.yml stop n8n || true

# Create backup archive
echo "Creating backup archive: $BACKUP_NAME.tar.gz"
docker run --rm \
    -v n8n_data:/data \
    -v "$BACKUP_DIR":/backup \
    alpine:latest \
    tar -czf "/backup/$BACKUP_NAME.tar.gz" -C /data .

# Restart n8n container
echo "Restarting n8n container..."
docker compose -f docker/docker-compose.n8n.yml start n8n || docker compose -f docker/docker-compose.nginx.yml start n8n || true

# Upload backup to Google Drive
echo "Uploading backup to Google Drive..."
rclone copy "$BACKUP_DIR/$BACKUP_NAME.tar.gz" "${RCLONE_REMOTE}:${GDRIVE_BACKUP_PATH}/"

# Verify upload
if rclone lsf "${RCLONE_REMOTE}:${GDRIVE_BACKUP_PATH}/" | grep -q "$BACKUP_NAME.tar.gz"; then
    echo "Backup uploaded successfully to Google Drive"
    # Remove local backup file after successful upload
    rm "$BACKUP_DIR/$BACKUP_NAME.tar.gz"
else
    echo "Error: Backup upload failed"
    exit 1
fi

# Clean up old backups (keep last 30)
echo "Cleaning up old backups (keeping last 30)..."
rclone ls "${RCLONE_REMOTE}:${GDRIVE_BACKUP_PATH}/" | \
    grep "n8n_backup_" | \
    sort -k2 | \
    head -n -30 | \
    while read size filename; do
        echo "Deleting old backup: $filename"
        rclone delete "${RCLONE_REMOTE}:${GDRIVE_BACKUP_PATH}/$filename"
    done

# List current backups
echo "Current backups in Google Drive:"
rclone ls "${RCLONE_REMOTE}:${GDRIVE_BACKUP_PATH}/" | grep "n8n_backup_" | sort -k2

echo "Backup process completed successfully!"
echo "Backup file: $BACKUP_NAME.tar.gz"
echo "Location: ${RCLONE_REMOTE}:${GDRIVE_BACKUP_PATH}/"