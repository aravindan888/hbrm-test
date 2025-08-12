#!/bin/bash

# Restore n8n data from Google Drive backup using rclone
# This script downloads and restores a backup from Google Drive

set -e

PROJECT_DIR="$HOME/hbrm-test"
BACKUP_DIR="$HOME/n8n-backups"
RCLONE_REMOTE="gdrive"
GDRIVE_BACKUP_PATH="n8n-backups"

echo "Starting n8n restore process..."

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "Error: rclone is not installed"
    echo "Please run the backup script first to install rclone"
    exit 1
fi

# Check if rclone is configured for Google Drive
if ! rclone listremotes | grep -q "^${RCLONE_REMOTE}:$"; then
    echo "Error: rclone is not configured for Google Drive"
    echo "Please run 'rclone config' to set up Google Drive remote named '${RCLONE_REMOTE}'"
    exit 1
fi

# List available backups
echo "Available backups in Google Drive:"
BACKUPS=$(rclone ls "${RCLONE_REMOTE}:${GDRIVE_BACKUP_PATH}/" | grep "n8n_backup_" | sort -k2 -r)

if [ -z "$BACKUPS" ]; then
    echo "No backups found in Google Drive"
    exit 1
fi

echo "$BACKUPS" | nl -w2 -s') '

# If BACKUP_FILE is not set, prompt user to select
if [ -z "$BACKUP_FILE" ]; then
    echo ""
    echo "Enter the number of the backup to restore (or 'latest' for the most recent):"
    read -r SELECTION

    if [ "$SELECTION" = "latest" ]; then
        BACKUP_FILE=$(echo "$BACKUPS" | head -n1 | awk '{print $2}')
    else
        BACKUP_FILE=$(echo "$BACKUPS" | sed -n "${SELECTION}p" | awk '{print $2}')
    fi
fi

if [ -z "$BACKUP_FILE" ]; then
    echo "Error: Invalid selection or backup file not specified"
    exit 1
fi

echo "Selected backup: $BACKUP_FILE"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Download backup from Google Drive
echo "Downloading backup from Google Drive..."
rclone copy "${RCLONE_REMOTE}:${GDRIVE_BACKUP_PATH}/$BACKUP_FILE" "$BACKUP_DIR/"

# Verify download
if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo "Error: Failed to download backup file"
    exit 1
fi

echo "Backup downloaded successfully"

# Stop n8n container
echo "Stopping n8n container..."
cd "$PROJECT_DIR"
docker compose -f docker/docker-compose.n8n.yml stop n8n || docker compose -f docker/docker-compose.nginx.yml stop n8n || true

# Create backup of current data before restore
echo "Creating backup of current data..."
CURRENT_BACKUP="n8n_backup_before_restore_$(date +"%Y%m%d_%H%M%S").tar.gz"
docker run --rm \
    -v n8n_data:/data \
    -v "$BACKUP_DIR":/backup \
    alpine:latest \
    tar -czf "/backup/$CURRENT_BACKUP" -C /data . || echo "Warning: Could not backup current data"

# Restore backup
echo "Restoring backup: $BACKUP_FILE"
docker run --rm \
    -v n8n_data:/data \
    -v "$BACKUP_DIR":/backup \
    alpine:latest \
    sh -c "rm -rf /data/* && tar -xzf /backup/$BACKUP_FILE -C /data"

# Start n8n container
echo "Starting n8n container..."
docker compose -f docker/docker-compose.n8n.yml start n8n || docker compose -f docker/docker-compose.nginx.yml start n8n || true

# Wait for n8n to start
echo "Waiting for n8n to start..."
sleep 10

# Verify n8n is running
if docker ps | grep -q n8n; then
    echo "n8n container is running"
else
    echo "Warning: n8n container may not be running properly"
fi

# Clean up downloaded backup file
rm "$BACKUP_DIR/$BACKUP_FILE"

echo "Restore process completed successfully!"
echo "Restored backup: $BACKUP_FILE"
echo "Current data backup saved as: $CURRENT_BACKUP"