#!/bin/bash
# NOMAD Oasis - Diagnostic Script
#
# This script runs a series of checks to verify the health of a NOMAD Oasis deployment.
# Usage: ./ops/kubernetes/scripts/check-status.sh

set -e

RELEASE_NAME="${RELEASE_NAME:-nomad-oasis}"
NAMESPACE="${NAMESPACE:-nomad-oasis}"

echo "=== NOMAD Oasis Diagnostic Check ==="
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Date: $(date)"
echo ""

# 1. Check Minikube Status
echo "[1/7] Checking Minikube Status..."
if command -v minikube &> /dev/null; then
    minikube status || echo "Minikube not running"
else
    echo "Minikube not found (skipping)"
fi
echo ""

# 2. Check Pod Status
echo "[2/7] Checking Pod Status..."
echo "--------------------------------------------------------"
kubectl get pods -n "$NAMESPACE" -o wide
echo "--------------------------------------------------------"
NOT_RUNNING=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -v "Running\|Completed" || true)
if [ -n "$NOT_RUNNING" ]; then
    echo "Some pods are not running!"
else
    echo "All pods are in Running/Completed state"
fi
echo ""

# 3. Check Services
echo "[3/7] Checking Services..."
kubectl get svc -n "$NAMESPACE"
echo ""

# 4. Check Ingress
echo "[4/7] Checking Ingress..."
kubectl get ingress -n "$NAMESPACE"
echo ""

# 5. Detailed Diagnostics for Unhealthy Pods
echo "[5/7] Checking for Unhealthy Pods..."
UNHEALTHY_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{if ($3 != "Running" && $3 != "Completed") print $1}' || true)

if [ -n "$UNHEALTHY_PODS" ]; then
    echo "Found unhealthy pods:"
    echo "$UNHEALTHY_PODS"
    echo ""
    for POD in $UNHEALTHY_PODS; do
        echo "=================================================================="
        echo "DESCRIBING POD: $POD"
        echo "=================================================================="
        kubectl describe pod -n "$NAMESPACE" "$POD" | grep -A 20 "Events:" || true
        echo ""
        echo "=================================================================="
        echo "LOGS (TAIL 20) FOR: $POD"
        echo "=================================================================="
        kubectl logs -n "$NAMESPACE" "$POD" --tail=20 --all-containers=true 2>/dev/null || echo "(No logs available)"
        echo ""
    done
else
    echo "No unhealthy pods found"
fi
echo ""

# 6. Check Application Logs
echo "[6/7] Checking Application Health..."
APP_POD=$(kubectl get pod -n "$NAMESPACE" -l "app.kubernetes.io/component=app" -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || true)

if [ -n "$APP_POD" ]; then
    echo "App Pod: $APP_POD"
    echo "Recent logs:"
    kubectl logs -n "$NAMESPACE" "$APP_POD" --tail=10 2>/dev/null || echo "(No logs available)"
else
    echo "App pod not found"
fi
echo ""

# 7. Internal Connectivity Check
echo "[7/7] Verifying Internal Connectivity..."
if [ -n "$APP_POD" ]; then
    echo "Checking health endpoint from inside the app pod..."
    HTTP_CODE=$(kubectl exec -n "$NAMESPACE" "$APP_POD" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/nomad-oasis/alive 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "Internal Health Check: OK (200)"
    else
        echo "Internal Health Check: HTTP $HTTP_CODE"
        echo "Debugging with verbose curl:"
        kubectl exec -n "$NAMESPACE" "$APP_POD" -- curl -v http://localhost:8000/nomad-oasis/alive 2>&1 || true
    fi
else
    echo "Skipping internal check (App pod not found)"
fi

echo ""
echo "=== Diagnostic Complete ==="
echo ""
echo "Tips:"
echo "  - If using minikube with ingress, ensure 'minikube tunnel' is running"
echo "  - Check /etc/hosts for hostname mapping (e.g., \$(minikube ip) nomad-oasis.local)"
