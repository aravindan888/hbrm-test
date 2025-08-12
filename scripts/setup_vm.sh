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

echo "VM setup completed successfully!"
