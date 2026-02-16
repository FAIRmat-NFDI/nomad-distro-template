#!/bin/bash

# Get the directory where the script is located and go to parent directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
BACKUP_DIR="$PARENT_DIR/.volumes/mongo"
CONTAINER_NAME="nomad_oasis_mongo"
DATABASE_NAME="nomad_oasis_v1"

# Run mongodump
docker exec "$CONTAINER_NAME" mongodump -d "$DATABASE_NAME" -o "/backup"

# Log completion
echo "$(date): Backup completed for $DATABASE_NAME" >> "$BACKUP_DIR/backup.log"
