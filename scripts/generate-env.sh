#!/bin/bash

# Script to generate a .env file with a random API secret

# Get the directory where the script is located and go to parent directory
PARENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$PARENT_DIR/.env"

# Check if .env file already exists
if [ -f "$ENV_FILE" ]; then
    echo "Warning: $ENV_FILE already exists."
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. $ENV_FILE was not modified."
        exit 0
    fi
fi

# Generate a random 64-character API secret using openssl
API_SECRET=$(openssl rand -hex 32)

# Create the .env file and check for errors
if ! cat > "$ENV_FILE" << EOF
NOMAD_SERVICES_API_SECRET='$API_SECRET'
EOF
then
    echo "Error: Failed to write to $ENV_FILE" >&2
    echo "Please check write permissions for the directory: $PARENT_DIR" >&2
    exit 1
fi

echo "✓ $ENV_FILE file created successfully!"
echo "✓ Generated a 64-character API secret."
echo ""
echo "You can now run 'docker compose up -d' to start NOMAD Oasis."
