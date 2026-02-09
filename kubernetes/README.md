# Deploying on Kubernetes

This folder contains an example `values.yaml` for deploying this NOMAD Oasis distribution
on Kubernetes using the [NOMAD Helm chart](https://github.com/FAIRmat-NFDI/nomad-helm-charts).

## Prerequisites

- A running Kubernetes cluster (or [Minikube](https://minikube.sigs.k8s.io/docs/start/) for local testing)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured to talk to your cluster
- [Helm](https://helm.sh/docs/intro/install/) v3+

## Quick Start

1. Add the NOMAD Helm chart repository:

    ```sh
    helm repo add nomad https://fairmat-nfdi.github.io/nomad-helm-charts
    helm repo update
    ```

2. Create a namespace:

    ```sh
    kubectl create namespace nomad-oasis
    ```

3. Edit `values.yaml` in this folder to match your environment. At a minimum, update:

    - `nomad.image.repository` / `nomad.image.tag` — your distribution image
    - `nomad.config.services.api_host` — the hostname where your Oasis will be reachable
    - `nomad.config.keycloak.*` — your Keycloak configuration
    - `nomad.config.meta.*` — deployment metadata

4. Install the chart:

    ```sh
    helm install nomad-oasis nomad/nomad -f values.yaml -n nomad-oasis
    ```

5. Check that all pods are running:

    ```sh
    kubectl get pods -n nomad-oasis
    ```

## Upgrading

After updating `values.yaml` or when a new chart version is available:

```sh
helm repo update
helm upgrade nomad-oasis nomad/nomad -f values.yaml -n nomad-oasis
```

## Uninstalling

```sh
helm uninstall nomad-oasis -n nomad-oasis
kubectl delete namespace nomad-oasis
```

## Further Reference

- [NOMAD Helm Charts repository](https://github.com/FAIRmat-NFDI/nomad-helm-charts) — chart source and full documentation
- [NOMAD Oasis documentation](https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/configure.html) — general Oasis configuration
