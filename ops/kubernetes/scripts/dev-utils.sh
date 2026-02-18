#!/bin/bash
# ops/kubernetes/scripts/dev-utils.sh
# Source this file to add helper aliases to your shell: source ops/kubernetes/scripts/dev-utils.sh

NAMESPACE="${NAMESPACE:-nomad-oasis}"

# Deployment Management
alias deploy-oasis='cd $(git rev-parse --show-toplevel)/ops/kubernetes && helm upgrade nomad-oasis ./nomad -f ./nomad/examples/oasis-minikube-values.yaml -n nomad-oasis'
alias install-oasis='cd $(git rev-parse --show-toplevel)/ops/kubernetes && helm install nomad-oasis ./nomad -f ./nomad/examples/oasis-minikube-values.yaml -n nomad-oasis --create-namespace'
alias restart-app='kubectl rollout restart deployment nomad-oasis-app nomad-oasis-worker -n nomad-oasis'
alias restart-hub='kubectl rollout restart deployment nomad-oasis-jupyterhub-hub -n nomad-oasis'
alias nuke-oasis='helm uninstall nomad-oasis -n nomad-oasis && kubectl delete pvc --all -n nomad-oasis'

# Diagnostics & Logs
alias check-status='$(git rev-parse --show-toplevel)/ops/kubernetes/scripts/check-status.sh'
alias logs-app='kubectl logs -l app.kubernetes.io/component=app -n nomad-oasis --tail=100 -f'
alias logs-worker='kubectl logs -l app.kubernetes.io/component=worker -n nomad-oasis --tail=100 -f'
alias logs-proxy='kubectl logs -l app.kubernetes.io/component=proxy -n nomad-oasis --tail=100 -f'
alias logs-temporal='kubectl logs -l app.kubernetes.io/name=temporal -n nomad-oasis --all-containers=true --tail=50'
alias logs-hub='kubectl logs -l app.kubernetes.io/component=hub -n nomad-oasis --tail=100 -f'

# Access & Port Forwarding
alias get-pods='kubectl get pods -n nomad-oasis'
alias get-svc='kubectl get svc -n nomad-oasis'
alias get-ingress='kubectl get ingress -n nomad-oasis'
alias port-forward-app='kubectl port-forward svc/nomad-oasis-app 8000:8000 -n nomad-oasis'
alias port-forward-proxy='kubectl port-forward svc/nomad-oasis-proxy 8080:80 -n nomad-oasis'

# Shell into pods
alias exec-app='kubectl exec -it $(kubectl get pod -l app.kubernetes.io/component=app -n nomad-oasis -o jsonpath="{.items[0].metadata.name}") -n nomad-oasis -- /bin/bash'

echo "NOMAD Oasis dev aliases loaded!"
echo ""
echo "Deployment:  install-oasis, deploy-oasis, restart-app, restart-hub, nuke-oasis"
echo "Diagnostics: check-status, logs-app, logs-worker, logs-proxy, logs-hub"
echo "Access:      get-pods, get-svc, port-forward-proxy, exec-app"
