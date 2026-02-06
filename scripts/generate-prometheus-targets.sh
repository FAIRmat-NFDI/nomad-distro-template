#!/bin/bash
set -e

OUTPUT_FILE="/etc/prometheus/targets.json"

# Get all worker container IPs
TARGETS=$(docker ps --filter "name=worker" --format "{{.Names}}" | while read container; do
  IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
  echo "\"$IP:9400\""
done | paste -sd "," -)

# Generate targets JSON
cat > "$OUTPUT_FILE" << EOF
[
  {
    "targets": [$TARGETS],
    "labels": {
      "job": "nomad-worker"
    }
  }
]
EOF

echo "Updated $OUTPUT_FILE with targets: $TARGETS"
