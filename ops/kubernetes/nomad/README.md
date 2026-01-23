# NOMAD Helm Chart

A Helm chart for deploying NOMAD on Kubernetes, including all required services (Elasticsearch, MongoDB, Temporal).

## Configuration Structure

The chart uses a clean configuration separation approach where all settings are under the `nomad` key:

### `nomad.config` (App Configuration)
Application-level NOMAD configuration. These values are written to `/app/nomad.yaml` in the container and also used by Kubernetes templates for ingress, volumes, and probes.

```yaml
nomad:
  config:
    services:
      api_host: localhost           # Used by ingress
      api_base_path: /nomad-oasis   # Used by ingress, nginx, probes
      api_port: 80
      https: false
    fs:
      staging_external: /data/nomad/staging   # Used for volume mounts
      public_external: /data/nomad/public
      north_home_external: /data/nomad/north/users
      nomad: /nomad
    mongo:
      db_name: nomad_oasis
      port: 27017
    temporal:
      enabled: true
      namespace: default
    # ... other NOMAD settings
```

### `nomad.*` (K8s Deployment Settings)
Kubernetes deployment configuration (replicas, resources, timeouts, secrets).

```yaml
nomad:
  enabled: true
  image:
    repository: gitlab-registry.mpcdf.mpg.de/nomad-lab/nomad-distro
    tag: latest

  proxy:
    replicaCount: 1
    timeout: 60
  app:
    replicaCount: 1
    resources:
      requests:
        memory: "512Mi"
  worker:
    replicaCount: 1
    terminationGracePeriodSeconds: 300

  secrets:
    api:
      existingSecret: ""    # Use pre-created K8s secret
      key: password
      value: ""             # Or set value directly (creates secret)
      autoGenerate: true    # Or auto-generate random secret
```

### `nomad.infrastructure` (Service Discovery)
Host overrides for external services. If empty, hosts are auto-computed from the release name.

```yaml
nomad:
  infrastructure:
    mongo:
      host: ""  # defaults to {{ .Release.Name }}-mongodb
    elastic:
      host: ""  # defaults to elasticsearch-master
```

## Secrets Management

The chart supports multiple methods for managing secrets:

### Method 1: Pre-created Kubernetes Secrets (Production)
```yaml
nomad:
  secrets:
    api:
      existingSecret: "my-api-secret"
      key: password
```

Create the secret manually:
```bash
kubectl create secret generic my-api-secret --from-literal=password=$(openssl rand -hex 32)
```

### Method 2: Values File (Development)
```yaml
nomad:
  secrets:
    api:
      value: "my-secret-value"
```

### Method 3: Auto-generate (Default)
```yaml
nomad:
  secrets:
    api:
      autoGenerate: true
```

### Method 4: Separate secrets.yaml File
Create a `secrets.yaml` file (keep out of git):
```yaml
nomad:
  secrets:
    api:
      value: "my-api-secret-here"
    keycloak:
      clientSecret:
        value: "keycloak-client-secret"
      password:
        value: "keycloak-password"
```

Install with both files:
```bash
helm install nomad ./nomad -f values.yaml -f secrets.yaml
```

### Method 5: Environment Variables with --set
```bash
helm install nomad ./nomad \
  -f values.yaml \
  --set nomad.secrets.api.value="${NOMAD_API_SECRET}"
```

### Method 6: helm-secrets Plugin
```bash
# Encrypt secrets with SOPS
sops -e secrets.yaml > secrets.enc.yaml

# Install with encrypted secrets
helm secrets install nomad ./nomad -f values.yaml -f secrets://secrets.enc.yaml
```

## Quick Start (Minikube)

### Prerequisites

```bash
# Start minikube with adequate resources
minikube start --cpus=6 --memory=12288

# Enable ingress
minikube addons enable ingress

# Create required directories
minikube ssh -- 'sudo mkdir -p /data/nomad/{public,staging,tmp,north/users} && sudo chmod -R 777 /data/nomad'
minikube ssh -- 'sudo mkdir -p /nomad && sudo chmod -R 777 /nomad'
```

### Install

```bash
# Update dependencies
helm dependency update ./ops/kubernetes/nomad

# Install using minikube example values (auto-generates API secret)
helm install nomad-oasis ./ops/kubernetes/nomad \
  -f ./ops/kubernetes/nomad/examples/oasis-minikube-values.yaml \
  --timeout 15m

# Watch pods
kubectl get pods -w
```

### Access NOMAD

```bash
# Port forward to the proxy service
kubectl port-forward svc/nomad-oasis-proxy 8080:80

# Open in browser
# http://localhost:8080/nomad-oasis/gui/
```

Or via ingress (add to /etc/hosts):
```bash
echo "$(minikube ip) localhost" | sudo tee -a /etc/hosts
# Then access: http://localhost/nomad-oasis/gui/
```

### Test Endpoints

```bash
# Alive check
curl http://localhost:8080/nomad-oasis/alive

# API info
curl http://localhost:8080/nomad-oasis/api/v1/info

# GUI
curl -I http://localhost:8080/nomad-oasis/gui/
```

### Uninstall

```bash
helm uninstall nomad-oasis
```

## Example Values Files

| File | Description |
|------|-------------|
| `examples/oasis-minikube-values.yaml` | Local development on Minikube with Temporal enabled |

## Temporal Workflow Engine

The chart includes Temporal for workflow orchestration. Key configuration:

```yaml
nomad:
  config:
    temporal:
      enabled: true
      namespace: default

temporal:
  enabled: true
  server:
    replicaCount: 1
  worker:
    # Temporal's internal system worker - disabled by default due to
    # known SDK client timeout issue in Temporal helm chart 0.72.0
    replicaCount: 0

postgresql:
  enabled: true  # Required for Temporal persistence
```

After installation, you may need to create the default namespace manually:
```bash
kubectl exec -it $(kubectl get pod -l app.kubernetes.io/name=temporal,app.kubernetes.io/component=admintools -o jsonpath='{.items[0].metadata.name}') \
  -- tctl --address nomad-oasis-temporal-frontend:7233 namespace register default --retention 168h
```

## Authentication (Keycloak)

NOMAD uses Keycloak for authentication. The chart supports three scenarios:

### Default: NOMAD Central Keycloak

By default, the chart points to the NOMAD central Keycloak server:

```yaml
nomad:
  config:
    keycloak:
      server_url: https://nomad-lab.eu/fairdi/keycloak/auth/
      realm_name: fairdi_nomad_test  # or fairdi_nomad_prod for production
      client_id: nomad_public
```

### Option 1: Local Keycloak Instance

For a self-hosted Keycloak (e.g., deployed alongside NOMAD):

```yaml
nomad:
  config:
    keycloak:
      server_url: http://keycloak.default.svc.cluster.local:8080/auth/
      realm_name: nomad
      username: admin
      client_id: nomad_oasis

  secrets:
    keycloak:
      clientSecret:
        existingSecret: "keycloak-client-secret"
      password:
        existingSecret: "keycloak-admin-password"
```

Create the required secrets:
```bash
kubectl create secret generic keycloak-client-secret --from-literal=password=<your-client-secret>
kubectl create secret generic keycloak-admin-password --from-literal=password=<your-admin-password>
```

### Option 2: Institution-Managed SSO

For integration with your institution's existing identity provider:

```yaml
nomad:
  config:
    keycloak:
      server_url: https://sso.your-institution.edu/auth/
      realm_name: institution_realm
      username: nomad-service-account
      client_id: nomad_oasis

  secrets:
    keycloak:
      clientSecret:
        existingSecret: "institution-sso-client-secret"
      password:
        existingSecret: "institution-sso-password"
```

> [!IMPORTANT]
> When using external SSO, coordinate with your institution's identity team to:
> - Register NOMAD as an OIDC client
> - Configure appropriate redirect URIs
> - Obtain client credentials

### Keycloak + JupyterHub (NORTH)

If NORTH is enabled, JupyterHub also needs OAuth configuration pointing to the same Keycloak realm:

```yaml
jupyterhub:
  hub:
    baseUrl: "/nomad-oasis/north"  # Must match api_base_path + /north
    config:
      GenericOAuthenticator:
        client_id: nomad_public
        oauth_callback_url: http://your-host/nomad-oasis/north/hub/oauth_callback
        authorize_url: https://nomad-lab.eu/fairdi/keycloak/auth/realms/fairdi_nomad_test/protocol/openid-connect/auth
        token_url: https://nomad-lab.eu/fairdi/keycloak/auth/realms/fairdi_nomad_test/protocol/openid-connect/token
        userdata_url: https://nomad-lab.eu/fairdi/keycloak/auth/realms/fairdi_nomad_test/protocol/openid-connect/userinfo
```

> [!NOTE]
> The `oauth_callback_url` must be registered as a valid redirect URI in the Keycloak client configuration.

## NORTH (JupyterHub Integration)

NORTH provides interactive computing environments via JupyterHub, allowing users to run analysis tools directly from NOMAD.

```yaml
nomad:
  config:
    north:
      enabled: false  # Disabled by default
```

### Enabling NORTH

To enable NORTH with JupyterHub:

```yaml
nomad:
  config:
    north:
      enabled: true
      hub_service_api_token: "your-secure-token"  # Used for NOMAD-JupyterHub communication
      hub_host: nomad-oasis-jupyterhub-hub        # JupyterHub hub service name
      hub_port: 8081                               # JupyterHub hub service port
      tools:
        options:
          jupyter:
            image: gitlab-registry.mpcdf.mpg.de/nomad-lab/nomad-distro/jupyter:develop

jupyterhub:
  enabled: true
  fullnameOverride: "nomad-oasis-jupyterhub"
  hub:
    baseUrl: "/nomad-oasis/north"
    config:
      GenericOAuthenticator:
        client_id: nomad_public
        oauth_callback_url: http://nomad-oasis.local/nomad-oasis/north/hub/oauth_callback
        authorize_url: https://nomad-lab.eu/fairdi/keycloak/auth/realms/fairdi_nomad_test/protocol/openid-connect/auth
        token_url: https://nomad-lab.eu/fairdi/keycloak/auth/realms/fairdi_nomad_test/protocol/openid-connect/token
        userdata_url: https://nomad-lab.eu/fairdi/keycloak/auth/realms/fairdi_nomad_test/protocol/openid-connect/userinfo
```

Create the hub service API token secret:
```bash
kubectl create secret generic nomad-hub-service-api-token \
  --from-literal=token=$(openssl rand -hex 32)
```

When enabled, the chart will:
1. Deploy the JupyterHub subchart
2. Configure nginx proxy to route `/api_base_path/north/` to JupyterHub
3. Configure OAuth authentication via Keycloak

### Custom Tools

Add custom tools to the NORTH configuration:

```yaml
nomad:
  config:
    north:
      enabled: true
      tools:
        options:
          jupyter:
            image: gitlab-registry.mpcdf.mpg.de/nomad-lab/nomad-distro/jupyter:develop
          my-custom-tool:
            image: my-registry/my-tool:latest
```

### NORTH Volume Requirements

NORTH requires a shared filesystem for user home directories:

```yaml
nomad:
  config:
    fs:
      north_home_external: /data/nomad/north/users  # Must be accessible by all nodes
```

For Minikube:
```bash
minikube ssh -- 'sudo mkdir -p /data/nomad/north/users && sudo chmod -R 777 /data/nomad/north/users'
```

## Troubleshooting

### Pods not starting
Check pod events:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Temporal schema job failing
The schema job may fail if PostgreSQL isn't ready. Delete and let it retry:
```bash
kubectl delete job --all
helm upgrade nomad-oasis ./ops/kubernetes/nomad -f <values-file>
```

### Volume mount issues
Ensure directories exist on the node:
```bash
minikube ssh -- 'ls -la /data/nomad/'
```

### Configuration Validation Warnings

The chart will display warnings during installation if there are configuration issues:
- `temporal is enabled in nomad.config but temporal subchart is disabled`
- `north is enabled in nomad.config but jupyterhub is disabled`
- `No API secret configured`

## Architecture

```
                    ┌─────────────┐
                    │   Ingress   │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │    Proxy    │ (nginx)
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼──────┐     │     ┌──────▼──────┐
       │     App     │     │     │   Worker    │
       └──────┬──────┘     │     └──────┬──────┘
              │            │            │
              └────────────┼────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
  ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
  │ Elasticsearch│   │   MongoDB   │   │  Temporal   │
  └─────────────┘   └─────────────┘   └─────────────┘
```
