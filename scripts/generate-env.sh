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
HUB_SERVICE_API_TOKEN=$(openssl rand -hex 32)

# Create the .env file and check for errors
if ! cat > "$ENV_FILE" << EOF
NOMAD_SERVICES_API_SECRET='$(openssl rand -hex 32)'

# API token for nomad services to communicate with the hub, can be generated with: openssl rand -hex 32
NOMAD_NORTH_HUB_SERVICE_API_TOKEN='$HUB_SERVICE_API_TOKEN'
EOF
then
    echo "Error: Failed to write to $ENV_FILE" >&2
    echo "Please check write permissions for the directory: $PARENT_DIR" >&2
    exit 1
fi


# Create the .env file and check for errors
if ! cat > "$ENV_FILE.north" << EOF
# OAuth2 settings for authentication with Keycloak
KEYCLOAK_URL="https://nomad-lab.eu/fairdi/keycloak"
KEYCLOAK_REALM="fairdi_nomad_prod"
OAUTH_CLIENT_ID="nomad_public"
OAUTH_CLIENT_SECRET=""

# API key for nomad services to communicate with the hub, can be generated with: openssl rand -hex 32
SERVICE_API_TOKEN='$HUB_SERVICE_API_TOKEN'

# Key for encryption of user_settings, can be generated with: openssl rand -hex 32
JUPYTERHUB_CRYPT_KEY='$(openssl rand -hex 32)'

EOF
then
    echo "Error: Failed to write to $ENV_FILE.north" >&2
    echo "Please check write permissions for the directory: $PARENT_DIR" >&2
    exit 1
fi




echo "✓ $ENV_FILE and $ENV_FILE.north files are created successfully!"
echo "✓ Generated a 64-character API token and encryption keys."
echo ""
echo "You can now run 'docker compose up -d' to start NOMAD Oasis."
