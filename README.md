![docker image](https://github.com/FAIRmat-NFDI/nomad-distro-template/actions/workflows/docker-publish.yml/badge.svg)

# NOMAD Oasis Distribution _Template_

This repository is a template for creating your own custom NOMAD Oasis distribution image.
Click [here](https://github.com/new?template_name=nomad-distro-template&template_owner=FAIRmat-NFDI)
to use this template, or click the `Use this template` button in the upper right corner of
the main GitHub page for this template.

> [!CAUTION]
> The templated repository will run a GitHub action on creation which might take a few minutes.
> After the workflow finishes you should refresh the page and this message should disappear.
> If this message persists you might need to trigger the workflow manually by navigating to the
> "Actions" tab at the top, clicking "Template Repository Initialization" on the left side,
> and triggering it by clicking "Run workflow" under the "Run workflow" button on the right.

# FAIRmat-NFDI's NOMAD Oasis Distribution

This is the NOMAD Oasis distribution of FAIRmat-NFDI.
Below are instructions for how to [deploy this distribution](#deploying-the-distribution)
and how to customize it through [adding plugins](#adding-a-plugin).

> [!IMPORTANT]
> Depending on the settings of the owner of this repository, the distributed image might
> be private and require authentication to pull.
> If you want to keep the image private you need to configure and use a personal access
> token (PAT) according to the instructions in the GitHub docs [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic).
> If you want to make the image public (recommended), you should make sure that your
> organization settings allow public packages and make this package public after building it.
> You can read more about this in the GitHub docs [here](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility).

> [!TIP]
> In order for others to find and learn from your distribution we in FAIRmat would
> greatly appreciate it if you would add the topic `nomad-distribution` by clicking the
> ⚙️ next to "About" on the main GitHub page for this repository.

In this README you will find instructions for:

1. [Deploying the distribution](#deploying-the-distribution)
2. [Adding a plugin](#adding-a-plugin)
3. [The Jupyter image](#the-jupyter-image)
4. [Using Docker image via plugin](#using-docker-image-via-plugin)
5. [Automated unit and example upload tests in CI](#automated-unit-and-example-upload-tests-in-ci)
6. [Setup regular package updates with Dependabot](#set-up-regular-package-updates-with-dependabot)
7. [Customizing Documentation](#customizing-documentation)
8. [Updating the distribution from the template](#updating-the-distribution-from-the-template)
9. [Solving common issues](#faqtrouble-shooting)

## Deploying the distribution

This distribution can be deployed using either Docker Compose or Kubernetes with Helm.

You can find more details on setting up and maintaining an Oasis in the NOMAD docs here:
[https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/configure.html](https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/configure.html)

### Docker Compose

The [`docker/`](docker/) folder contains the Docker Compose configuration for deploying a NOMAD Oasis
distribution (recommended for single-server setups).

**Prerequisites:** [Docker](https://docs.docker.com/engine/install/) (with `docker compose` built in).

#### For a new Oasis

1. Clone the repository and navigate to the `docker` directory:

   ```sh
   git clone https://github.com/FAIRmat-NFDI/nomad-distro-template.git
   cd nomad-distro-template/docker
   ```

2. _On Linux only,_ recursively change the owner of the `.volumes` directory to the nomad user (1000):

   ```sh
   sudo chown -R 1000 .volumes
   ```

3. Create a `.env` file for environment variables.

   At a minimum, you need a secure API secret (at least 32 characters):

   ```
   NOMAD_SERVICES_API_SECRET='***'
   ```

   You can generate one automatically using the provided script:

   ```sh
   bash ../scripts/generate-env.sh
   ```

4. Pull the images specified in `docker-compose.yaml`:

   > **Note:** The image needs to be public or you need to provide a
   > [PAT](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic).

   ```sh
   docker compose pull
   ```

5. Configure HTTP or HTTPS.

   By default the setup uses HTTP. Before entering production you must switch to HTTPS.

   **HTTPS requires a TLS certificate.** Options include:
   - An existing certificate you already have
   - A free certificate from [Let's Encrypt](https://letsencrypt.org/)
   - A self-signed certificate (for testing only):

     ```sh
     mkdir ssl
     openssl req -x509 -nodes -days 365 \
       -newkey rsa:2048 \
       -keyout ./ssl/selfsigned.key \
       -out ./ssl/selfsigned.crt \
       -subj "/CN=localhost"
     ```

   To enable HTTPS, update the `proxy` service in `docker-compose.yaml`:

   ```diff
   - # HTTP
   - - ./configs/nginx_http.conf:/etc/nginx/conf.d/default.conf:ro

   + # HTTPS
   + - ./configs/nginx_https.conf:/etc/nginx/conf.d/default.conf:ro
   + - ./ssl:/etc/nginx/ssl:ro
   ```

6. Start the services:

   ```sh
   docker compose up -d
   ```

7. Verify that NOMAD is running:

   ```sh
   # HTTP
   curl localhost/nomad-oasis/alive

   # HTTPS (--insecure only needed for self-signed certificates)
   curl --insecure https://localhost/nomad-oasis/alive
   ```

8. Open [http://localhost/nomad-oasis](http://localhost/nomad-oasis) in your browser.

#### Updating the image

Pushes to the main branch trigger a pipeline that builds a new image.

1. Shut down NOMAD:

   ```sh
   docker compose down
   ```

2. Pull the latest images and restart:

   ```sh
   docker compose pull
   docker compose up -d
   ```

3. Optionally remove unused images:

   ```sh
   docker image prune -a
   ```

#### For an existing Oasis

If you already have an Oasis running, update the image in your `docker-compose.yaml` to
`ghcr.io/fairmat-nfdi/nomad-distro-template:main` for the services `worker`, `app`, `north`,
and `logtransfer`.

If you want to use the `nomad.yaml` from this repository, comment out the volume mount
in those services:

```yaml
volumes:
  # - ../nomad.yaml:/app/nomad.yaml
```

Then pull and restart (steps 4 and 6 above).

#### NOMAD Remote Tools Hub (NORTH)

The `north` (JupyterHub) container needs access to Docker. Replace the default group id `991`
in the `docker-compose.yaml` `north` section with your system's docker group id.

Find your docker group id:

```sh
id            # if you are a docker user
getent group | grep docker  # otherwise
```

The user id `1000` is the nomad user inside all containers.

#### Configuring Worker Replicas and Resource Limits

The `docker-compose.yaml` runs four worker replicas by default, each limited to 4 CPU cores
and 8 GB RAM:

```yaml
services:
  worker:
    deploy:
      replicas: 4
      resources:
        limits:
          cpus: "4.0"
          memory: 8G
```

Adjust these values to match your server's capacity.

#### Backing up the Oasis

See the [NOMAD documentation on backups](https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/administer.html#backups).

A backup script is provided at [`scripts/backup-mongo.sh`](scripts/backup-mongo.sh):

```sh
# From the docker/ directory
bash ../scripts/backup-mongo.sh
```

Check the backup:

```sh
ls .volumes/mongo
cat .volumes/mongo/backup.log
```

Optionally schedule nightly backups via cron:

```sh
(crontab -l 2>/dev/null; echo "0 2 * * * bash $(realpath ../scripts/backup-mongo.sh)") | crontab -
```

#### Enabling NOMAD Actions

1. Uncomment the `cpu_worker` and/or `gpu_worker` service(s) in `docker-compose.yaml`.
2. Enable the corresponding build step(s) in `.github/workflows/docker-publish.yml`.
3. Adjust resource limits as needed.

### Kubernetes

The [`kubernetes/`](kubernetes/) folder contains an example [`values.yaml`](kubernetes/values.yaml)
for deploying this NOMAD Oasis distribution on Kubernetes using the
[NOMAD Helm chart](https://github.com/FAIRmat-NFDI/nomad-helm-charts).

**Prerequisites:**

- A running Kubernetes cluster (or [Minikube](https://minikube.sigs.k8s.io/docs/start/) for local testing)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured to talk to your cluster
- [Helm](https://helm.sh/docs/intro/install/) v3+

#### Quick Start

1. Add the NOMAD Helm chart repository:

   ```sh
   helm repo add nomad https://fairmat-nfdi.github.io/nomad-helm-charts
   helm repo update
   ```

2. Create a namespace:

   ```sh
   kubectl create namespace nomad-oasis
   ```

3. Edit [`kubernetes/values.yaml`](kubernetes/values.yaml) to match your environment. At a minimum, update:
   - `nomad.image.repository` / `nomad.image.tag` — your distribution image
   - `nomad.config.services.api_host` — the hostname where your Oasis will be reachable
   - `nomad.config.keycloak.*` — your Keycloak configuration
   - `nomad.config.meta.*` — deployment metadata

4. Install the chart:

   ```sh
   helm install nomad-oasis nomad/nomad -f kubernetes/values.yaml -n nomad-oasis
   ```

5. Check that all pods are running:

   ```sh
   kubectl get pods -n nomad-oasis
   ```

#### Upgrading

After updating `values.yaml` or when a new chart version is available:

```sh
helm repo update
helm upgrade nomad-oasis nomad/nomad -f kubernetes/values.yaml -n nomad-oasis
```

#### Uninstalling

```sh
helm uninstall nomad-oasis -n nomad-oasis
kubectl delete namespace nomad-oasis
```

#### Further Reference

- [NOMAD Helm Charts repository](https://github.com/FAIRmat-NFDI/nomad-helm-charts) — chart source and full documentation
- [NOMAD Oasis documentation](https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/configure.html) — general Oasis configuration

## Adding a plugin

By default, no plugins are included in this distribution. You can find a list of available NOMAD plugins [here](https://nomad-lab.eu/prod/v1/oasis/gui/search/plugins). For a list of official plugins provided by FAIRmat, please see [here](https://github.com/FAIRmat-NFDI/.github/blob/main/profile/README.md). For inspiration, you can also check the list of [plugins that are installed on the production NOMAD deployment hosted by FAIRmat](https://gitlab.mpcdf.mpg.de/nomad-lab/nomad-distro/-/raw/main/pyproject.toml?ref_type=heads).

To add a new plugin to the docker image you should add it to the plugins table in the [`pyproject.toml`](pyproject.toml) file.

Here you can put either plugins distributed to PyPI, e.g.

```toml
[project.optional-dependencies]
plugins = [
  "nomad-material-processing>=1.0.0",
  "nomad-north-jupyter>=0.1.0",
]
```

or plugins in a git repository with either the commit hash

```toml
[project.optional-dependencies]
plugins = [
  "nomad-measurements @ git+https://github.com/FAIRmat-NFDI/nomad-measurements.git@71b7e8c9bb376ce9e8610aba9a20be0b5bce6775",
]
```

or with a tag

```toml
[project.optional-dependencies]
plugins = [
  "nomad-measurements @ git+https://github.com/FAIRmat-NFDI/nomad-measurements.git@v0.0.4"
]
```

To add a plugin in a subdirectory of a git repository you can use the `subdirectory` option, e.g.

```toml
[project.optional-dependencies]
plugins = [
  "ikz_pld_plugin @ git+https://github.com/FAIRmat-NFDI/AreaA-data_modeling_and_schemas.git@30fc90843428d1b36a1d222874803abae8b1cb42#subdirectory=PVD/PLD/jeremy_ikz/ikz_pld_plugin"
]
```

Once the changes have been committed to the main branch, the new image will automatically
be generated.

## The Jupyter image

In addition to the Docker image for running the oasis, this repository also builds a custom NORTH image for running a jupyter hub with the installed plugins.
This image has been added to the [`nomad.yaml`](nomad.yaml) during the initialization of this repository and should therefore already be available in your Oasis under "Analyze / NOMAD Remote Tools Hub / jupyter"

We currently use `quay.io/jupyter/base-notebook:2025-04-14` as our base image for Jupyter (see Dockerfile). While it includes the necessary Python packages, it does not come with `R` or `Julia` pre-installed.
If you need support for those languages, you can switch to `quay.io/jupyter/datascience-notebook:2025-04-04`, which includes both `R` and `Julia`.
The Jupyter image does not include `gcc` or `build-essential` by default. If you want to allow users to install Python packages that require compilation while running a notebook, you'll need to install these tools in the [Dockerfile](./Dockerfile#L172) or switch the base image to `quay.io/jupyter/datascience-notebook:2025-04-04`.
However, including these packages can increase the image size and may introduce security risks if arbitrary code is compiled at runtime.

Note that the `base-notebook` image is more lightweight and uses less disk space compared to the `datascience-notebook` image.

The image is quite large and might cause a timeout the first time it is run. In order to avoid this you can pre pull the image with:

```sh
docker pull ghcr.io/fairmat-nfdi/nomad-distro-template/jupyter:main
```

If you want additional python packages to be available to all users in the jupyter hub you can add those to the jupyter table in the [`pyproject.toml`](pyproject.toml):

```toml
[project.optional-dependencies]
jupyter = [
  "voila",
  "ipyaggrid",
  "ipysheet",
  "ipydatagrid",
  "jupyter-flex",
]
```

## Using Docker image via plugin

The recommended way to integrate the Docker image e.g., Jupyter into your NOMAD Oasis is through the plugin entry point system. This approach is cleaner, more maintainable, and automatically handles all necessary configurations.

[`nomad-north-jupyter`](https://github.com/FAIRmat-NFDI/nomad-north-jupyter) is a NOMAD plugin that provides a containerized JupyterLab environment for interactive analysis within NORTH (NOMAD Remote Tools Hub). This plugin has been added to this distribution by default via `pyproject.toml`. In `nomad.yaml`, the `NORTHTool` entry point is configured to use the [custom Jupyter image](#the-jupyter-image) built in this repository.

## Automated Unit and Example Upload Tests in CI

By default, all unit tests from every plugin are executed to ensure system stability and catch potential issues early. These tests validate core functionality and help maintain consistency across different plugins.

In addition to unit tests, the pipeline also verifies that all example uploads can be processed correctly. This ensures that any generated entries do not contain error messages, providing confidence that data flows through the system as expected.

For example upload tests, the CI uses the image built in the Build Image step. It then runs the Docker container and starts up the application to confirm that it functions correctly. This approach ensures that if the pipeline passes, the app is more likely to run smoothly in a Dockerized environment on a server, not just locally.

If you need to disable tests for specific plugins, update the **PLUGIN_TESTS_PLUGINS_TO_SKIP** variable in [.github/workflows/docker-publish.yml](./.github/workflows/docker-publish.yml#L21) by adding the plugin names to the existing list.

## Set Up Regular Package Updates with Dependabot

Dependabot is already configured in the repository's CI setup, but you need to enable it manually in the repository settings.

To enable Dependabot, go to Settings > Code security and analysis in your GitHub repository. From there, turn on Dependabot alerts and version updates. Once enabled, Dependabot will automatically check for dependency updates and create pull requests when new versions are available.

This automated process helps ensure that your dependencies stay up to date, improving security and reducing the risk of vulnerabilities.

## Customizing Documentation

By default, documentation is built using the [nomad-docs](https://github.com/FAIRmat-NFDI/nomad-docs) repository. However, if you'd like to customize the documentation for your Oasis instance, you can easily do so.

1. First, [fork the nomad-docs repository](https://github.com/FAIRmat-NFDI/nomad-docs/fork).
2. Make your desired changes in your fork.
3. Update the `NOMAD_DOCS_REPO` variable in the [.github/workflows/docker-publish.yml](./.github/workflows/docker-publish.yml#L19) file to point to the URL of your forked repository.

This setup ensures that your custom documentation is used when building your Oasis.

## Updating the distribution from the template

In order to update an existing distribution with any potential changes in the template you can add a new `git remote` for the template and merge with that one while allowing for unrelated histories:

```sh
git remote add template https://github.com/FAIRmat-NFDI/nomad-distro-template
git fetch template
git merge template/main --allow-unrelated-histories
```

Most likely this will result in some merge conflicts which will need to be resolved. At the very least the `Dockerfile` and GitHub workflows should be taken from "theirs":

```sh
git checkout --theirs Dockerfile
git checkout --theirs .github/workflows/docker-publish.yml
```

The lock file merge conflicts can be resolved to use your versions instead of the template repository resolution.

```sh
git checkout --ours uv.lock
```

For detailed instructions on how to resolve the merge conflicts between different version we refer you to the latest template release [notes](https://github.com/FAIRmat-NFDI/nomad-distro-template/releases/latest)

Once the merge conflicts are resolved you should add the changes and commit them

```sh
git add -A
git commit -m "Updated to new distribution version"
```

Ideally all workflows should be triggered automatically but you might need to run the initialization one manually by navigating to the "Actions" tab at the top, clicking "Template Repository Initialization" on the left side, and triggering it by clicking "Run workflow" under the "Run workflow" button on the right.

## FAQ/Trouble shooting

_I get an_ `Error response from daemon: Head "https://ghcr.io/v2/FAIRmat-NFDI/nomad-distro-template/manifests/main": unauthorized`
_when trying to pull my docker image._

Most likely you have not made the package public or provided a personal access token (PAT).
You can read how to make your package public in the GitHub docs [here](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)
or how to configure a PAT (if you want to keep the distribution private) in the GitHub
docs [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic).
