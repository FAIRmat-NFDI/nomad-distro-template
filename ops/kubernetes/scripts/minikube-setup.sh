#!/bin/bash
# NOMAD Oasis - Reproducible Minikube Setup
#
# This script provides a clean, reproducible environment for testing the NOMAD Helm chart.
# Run from the nomad-distro repository root.
#
# Usage: ./ops/kubernetes/scripts/minikube-setup.sh

set -euo pipefail

# Configuration
MINIKUBE_CPUS="${MINIKUBE_CPUS:-6}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-12288}"
MINIKUBE_DISK="${MINIKUBE_DISK:-40g}"
MINIKUBE_DRIVER="${MINIKUBE_DRIVER:-docker}"
RELEASE_NAME="${RELEASE_NAME:-nomad-oasis}"
NAMESPACE="${NAMESPACE:-nomad-oasis}"
HOSTNAME="${HOSTNAME:-nomad-oasis.local}"

echo "=== NOMAD Oasis Minikube Setup ==="
echo "CPUs: $MINIKUBE_CPUS, Memory: ${MINIKUBE_MEMORY}MB, Disk: $MINIKUBE_DISK"
echo "Namespace: $NAMESPACE, Hostname: $HOSTNAME"

# Step 1: Clean up any existing minikube
echo ""
echo "Step 1: Cleaning up existing minikube..."
minikube delete 2>/dev/null || true

# Step 2: Start fresh minikube
echo ""
echo "Step 2: Starting fresh minikube..."
minikube start \
  --cpus="$MINIKUBE_CPUS" \
  --memory="$MINIKUBE_MEMORY" \
  --disk-size="$MINIKUBE_DISK" \
  --driver="$MINIKUBE_DRIVER"

# Step 3: Enable required addons
echo ""
echo "Step 3: Enabling addons..."
minikube addons enable ingress
minikube addons enable storage-provisioner

# Step 4: Create host directories for nomad data
echo ""
echo "Step 4: Creating data directories on minikube node..."
minikube ssh -- 'sudo mkdir -p /data/nomad/{public,staging,north/users,tmp}'
minikube ssh -- 'sudo chmod -R 777 /data/nomad'
minikube ssh -- 'sudo mkdir -p /nomad && sudo chmod -R 777 /nomad'

# Step 5: Update Helm dependencies
echo ""
echo "Step 5: Updating Helm dependencies..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../nomad"
helm dependency update .

# Step 6: Create namespace and secrets
echo ""
echo "Step 6: Creating namespace and secrets..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic nomad-hub-service-api-token \
  --from-literal=token=secret-token \
  -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Step 7: Install the chart
echo ""
echo "Step 7: Installing NOMAD Oasis chart..."
helm install "$RELEASE_NAME" . \
  -f examples/oasis-minikube-values.yaml \
  -n "$NAMESPACE" \
  --timeout 15m

# Step 8: Wait for pods
echo ""
echo "Step 8: Waiting for pods to be ready..."
echo "This may take several minutes as the app loads plugins..."
kubectl wait --for=condition=ready pod \
  -l "app.kubernetes.io/component=app" \
  --timeout=600s \
  -n "$NAMESPACE" || echo "Warning: App pod not ready yet (may still be loading)"

# Step 9: Show status
echo ""
echo "=== Installation Complete ==="
echo ""
kubectl get pods -n "$NAMESPACE"
echo ""

# Step 10: Setup /etc/hosts
MINIKUBE_IP=$(minikube ip)
echo "To access NOMAD Oasis:"
echo ""
echo "  1. Add to /etc/hosts:"
echo "     echo '$MINIKUBE_IP $HOSTNAME' | sudo tee -a /etc/hosts"
echo ""
echo "  2. Start tunnel (in separate terminal):"
echo "     minikube tunnel"
echo ""
echo "  3. Open in browser:"
echo "     http://$HOSTNAME/nomad-oasis/gui/"
echo ""
echo "To check status:"
echo "  ./ops/kubernetes/scripts/check-status.sh"
echo ""
echo "To uninstall:"
echo "  helm uninstall $RELEASE_NAME -n $NAMESPACE"
echo ""
echo "To delete minikube completely:"
echo "  minikube delete"
