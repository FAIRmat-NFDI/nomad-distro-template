#!/usr/bin/env bash
# Deployment mode setup for NOMAD Oasis distributions.
# Removes the deployment folder that is not needed and updates the README accordingly.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT_DIR/README.md"

# ── Prompt ───────────────────────────────────────────────────────────────────

echo "NOMAD Oasis Distribution — deployment setup"
echo "============================================"
echo ""
echo "Which deployment method would you like to use?"
echo "  1) docker      Docker Compose (single-server)"
echo "  2) kubernetes  Kubernetes with Helm"
echo ""

while true; do
  read -rp "Select [1/2]: " choice
  case "$choice" in
    1|docker)     MODE="docker";     break ;;
    2|kubernetes) MODE="kubernetes"; break ;;
    *) echo "Please enter 1 or 2." ;;
  esac
done

# ── Remove the unused deployment folder ──────────────────────────────────────

if [ "$MODE" = "docker" ]; then
  REMOVE_DIR="$ROOT_DIR/kubernetes"
  REMOVE_NAME="kubernetes"
else
  REMOVE_DIR="$ROOT_DIR/docker"
  REMOVE_NAME="docker"
fi

if [ -d "$REMOVE_DIR" ]; then
  rm -rf "$REMOVE_DIR"
  echo "Removed $REMOVE_NAME/."
else
  echo "$REMOVE_NAME/ already absent — skipping."
fi

# ── Update README ────────────────────────────────────────────────────────────

if [ -f "$README" ]; then
  if [ "$MODE" = "docker" ]; then
    # Remove the Kubernetes subsection (from ### Kubernetes up to the next ### or ##)
    sed -i '/^### Kubernetes$/,/^###\|^## /{/^### [^K]\|^## /!d}' "$README"
    # Simplify the intro line
    sed -i 's/^This distribution can be deployed using either Docker Compose or Kubernetes with Helm\.$/This distribution is deployed using Docker Compose./' "$README"

  else
    # Remove the Docker Compose subsection (from ### Docker Compose up to the next ### or ##)
    sed -i '/^### Docker Compose$/,/^###\|^## /{/^### [^D]\|^## /!d}' "$README"
    # Simplify the intro line
    sed -i 's/^This distribution can be deployed using either Docker Compose or Kubernetes with Helm\.$/This distribution is deployed on Kubernetes with Helm./' "$README"
    # Update the Jupyter image config reference from docker path to kubernetes
    sed -i 's|\[`docker/configs/nomad.yaml`\](docker/configs/nomad.yaml)|\[`kubernetes/values.yaml`\](kubernetes/values.yaml)|' "$README"
  fi

  # Remove the setup.sh reference line (no longer needed after running)
  sed -i '/^bash scripts\/setup\.sh$/d' "$README"

  echo "Updated README.md."
fi

# ── Clean up .gitignore (docker-specific entries) ────────────────────────────

if [ "$MODE" = "kubernetes" ]; then
  GITIGNORE="$ROOT_DIR/.gitignore"
  if [ -f "$GITIGNORE" ]; then
    sed -i '/^# Docker runtime artifacts$/d' "$GITIGNORE"
    sed -i '/^docker\/\.volumes\/$/d' "$GITIGNORE"
    sed -i '/^docker\/\.env$/d' "$GITIGNORE"
    sed -i '/^docker\/ssl\/$/d' "$GITIGNORE"
    echo "Cleaned docker entries from .gitignore."
  fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "Done. Deployment mode set to: $MODE"
echo "You can commit these changes with:"
echo "  git add -A && git commit -m 'Set deployment mode to $MODE'"
