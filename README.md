![docker image](https://github.com/FAIRmat-NFDI/nomad-distro-template/actions/workflows/docker-publish.yml/badge.svg)

# NOMAD Oasis Distribution *Template*
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
2. [Configuring Worker Replicas and Resource Limits](#configuring-worker-replicas-and-resource-limits)
3. [Adding a plugin](#adding-a-plugin)
4. [Using the jupyter image](#the-jupyter-image)
5. [Automated unit and example upload tests in CI](#automated-unit-and-example-upload-tests-in-ci)
6. [Setup regular package updates with Dependabot](#set-up-regular-package-updates-with-dependabot)
7. [Customizing Documentation](#customizing-documentation)
8. [Backing up the Oasis](#backing-up-the-oasis)
9. [Enabling NOMAD Actions](#enabling-nomad-actions)
10. [Updating the distribution from the template](#updating-the-distribution-from-the-template)
11. [Solving common issues](#faqtrouble-shooting)

## Deploying the distribution

Below are instructions for how to deploy this NOMAD Oasis distribution
[for a new Oasis](#for-a-new-oasis) and [for an existing Oasis](#for-an-existing-oasis)

### For a new Oasis

1. Make sure you have [docker](https://docs.docker.com/engine/install/) installed.
   Docker nowadays comes with `docker compose` built in. Prior, you needed to
   install the stand-alone [docker-compose](https://docs.docker.com/compose/install/).

2. Clone the repository or download the repository as a zip file.

    ```sh
    git clone https://github.com/FAIRmat-NFDI/nomad-distro-template.git
    cd nomad-distro-template
    ```

    or

    ```sh
    curl-L -o nomad-distro-template.zip "https://github.com/FAIRmat-NFDI/nomad-distro-template/archive/main.zip"
    unzip nomad-distro-template.zip
    cd nomad-distro-template
    ```

3. _On Linux only,_ recursively change the owner of the `.volumes` directory to the nomad user (1000)

    ```sh
    sudo chown -R 1000 .volumes
    ```

4. Create a file for environment variables

    Before running the containers, you should create a `.env` file in the root of the repository. This file is used to store sensitive information and is ignored by git.

    At a minimum, you should add a secure secret for the API:

    ```
    NOMAD_SERVICES_API_SECRET='***'
    ```

    Make sure the `NOMAD_SERVICES_API_SECRET` is at least 32 characters long.

    If you have bash available you can run this script:

    ```sh
    bash scripts/generate-env.sh
    ```

    This will create a `.env` file with a randomly generated 64-character API secret. If the file already exists, you'll be prompted before overwriting it.

5. Pull the images specified in the `docker-compose.yaml`

    Note that the image needs to be public or you need to provide a PAT (see "Important" note above).

    ```sh
    docker compose pull
    ```

6. Configuring Secure HTTP and HTTPS Connections

   By default `docker-compose.yaml` uses the HTTP protocol for communication. This works for testing, but before entering production you must secure your setup with HTTPS; otherwise, any communication with the server—including credentials and sensitive data—can be compromised.

   HTTPS requires a TLS certificate, which must be renewed periodically. Depending on your setup, you have several options:

   1. You already have a certificate.

      In this case, you just need the certificate and key files.

   2. Free certificate from Let's Encrypt

      [Let's Encrypt](https://letsencrypt.org/) provides free TLS certificates for those with a domain name. Follow their tutorials for instructions on generating a certificate.

   3. Self-signed certificate

      For testing, you can create a [self-signed certificate](https://en.wikipedia.org/wiki/Self-signed_certificate). Note that self-signed certificates are not recommended for production since they are not trusted by browsers. You can generate one with:

      ```sh
      mkdir ssl
      openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout ./ssl/selfsigned.key \
        -out ./ssl/selfsigned.crt \
        -subj "/CN=localhost"
      ```

   To start using a TLS certificate, update the `proxy` configuration in `docker-compose.yml`:
   ```diff
   - # HTTP
   - - ./configs/nginx_http.conf:/etc/nginx/conf.d/default.conf:ro

   + # HTTPS
   + - ./configs/nginx_https.conf:/etc/nginx/conf.d/default.conf:ro
   + - ./ssl:/etc/nginx/ssl:ro  # Your certificate files
   ```

7. And run it with docker compose in detached (--detach or -d) mode

    ```sh
    docker compose up -d
    ```

8. (Optional) You can now test that NOMAD is running with

    ```sh
    # HTTP
    curl localhost/nomad-oasis/alive

    # HTTPS (--insecure flag is only needed for a self-signed certificate)
    curl --insecure https://localhost/nomad-oasis/alive
    ```

9. Finally, open [http://localhost/nomad-oasis](http://localhost/nomad-oasis) in your browser to start using your new NOMAD Oasis.

#### Updating the image
Any pushes to the main branch of this repository, such as when [adding a plugin](#adding-a-plugin), will trigger a pipeline that generates a new app and jupyter image.

1. To update your local image you need to shut down NOMAD using

    ```sh
    docker compose down
    ```

    and then repeat steps 5. and 7. above.

2. You can remove unused images to free up space by running

    ```sh
    docker image prune -a
    ```

#### NOMAD Remote Tools Hub (NORTH)

To run NORTH (the NOMAD Remote Tools Hub), the `hub` container needs to run docker and
the container has to be run under the docker group. You need to replace the default group
id `991` in the `docker-compose.yaml`'s `hub` section with your systems docker group id.
Run `id` if you are a docker user, or `getent group | grep docker` to find your
systems docker gid. The user id 1000 is used as the nomad user inside all containers.

Please see the [Jupyter image](#the-jupyter-image) section below for more information on the jupyter NORTH image being generated in this repository.

You can find more details on setting up and maintaining an Oasis in the NOMAD docs here:
[https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/configure.html](https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/configure.html)

### For an existing Oasis

If you already have an Oasis running you only need to change the image being pulled in
your `docker-compose.yaml` with `ghcr.io/fairmat-nfdi/nomad-distro-template:main` for the services
`worker`, `app`, `north`, and `logtransfer`.

If you want to use the `nomad.yaml` from this repository you also need to comment out
the inclusion of the `nomad.yaml` under the volumes key of those services in the
`docker-compose.yaml`.

```yaml
volumes:
  # - ./configs/nomad.yaml:/app/nomad.yaml
```

To run the new image you can follow steps 5. and 7. [above](#for-a-new-oasis).

## Configuring Worker Replicas and Resource Limits

The `docker-compose.yaml` file is configured to run four worker replicas by default, with each limited to 4 CPU cores and 8GB of RAM. You can adjust these values to match the capacity of your server.

The relevant configuration is located in the `worker` service definition within the `docker-compose.yaml` file:

```yaml
services:
  worker:
    ...
    deploy:
      replicas: 4
      resources:
        limits:
          cpus: "4.0" # Maximum 4 CPU cores
          memory: 8G # Maximum 8GB RAM
```

-   `replicas`: The number of container instances to run for the worker service.
-   `cpus`: The maximum number of CPU cores the container can use.
-   `memory`: The maximum amount of memory the container can use.

Adjust these values based on your server's available resources to optimize performance.

## Adding a plugin

To add a new plugin to the docker image you should add it to the plugins table in the [`pyproject.toml`](pyproject.toml) file.

Here you can put either plugins distributed to PyPI, e.g.

```toml
[project.optional-dependencies]
plugins = [
  "nomad-material-processing>=1.0.0",
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
This image has been added to the [`configs/nomad.yaml`](configs/nomad.yaml) during the initialization of this repository and should therefore already be available in your Oasis under "Analyze / NOMAD Remote Tools Hub / jupyter"

We currently use `quay.io/jupyter/base-notebook:2025-04-14` as our base image for Jupyter. While it includes the necessary Python packages, it does not come with `R` or `Julia` pre-installed.
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

## Automated Unit and Example Upload Tests in CI

By default, all unit tests from every plugin are executed to ensure system stability and catch potential issues early. These tests validate core functionality and help maintain consistency across different plugins.

In addition to unit tests, the pipeline also verifies that all example uploads can be processed correctly. This ensures that any generated entries do not contain error messages, providing confidence that data flows through the system as expected.

For example upload tests, the CI uses the image built in the Build Image step. It then runs the Docker container and starts up the application to confirm that it functions correctly. This approach ensures that if the pipeline passes, the app is more likely to run smoothly in a Dockerized environment on a server, not just locally.

If you need to disable tests for specific plugins, update the **PLUGIN_TESTS_PLUGINS_TO_SKIP** variable in [.github/workflows/docker-publish.yml](./.github/workflows/docker-publish.yml#L21) by adding the plugin names to the existing list.

## Set Up Regular Package Updates with Dependabot

Dependabot is already configured in the repository’s CI setup, but you need to enable it manually in the repository settings.

To enable Dependabot, go to Settings > Code security and analysis in your GitHub repository. From there, turn on Dependabot alerts and version updates. Once enabled, Dependabot will automatically check for dependency updates and create pull requests when new versions are available.

This automated process helps ensure that your dependencies stay up to date, improving security and reducing the risk of vulnerabilities.

## Customizing Documentation

By default, documentation is built using the [nomad-docs](https://github.com/FAIRmat-NFDI/nomad-docs) repository. However, if you'd like to customize the documentation for your Oasis instance, you can easily do so.

1. First, [fork the nomad-docs repository](https://github.com/FAIRmat-NFDI/nomad-docs/fork).
2. Make your desired changes in your fork.
3. Update the `NOMAD_DOCS_REPO` variable in the [.github/workflows/docker-publish.yml](./.github/workflows/docker-publish.yml#L19) file to point to the URL of your forked repository.

This setup ensures that your custom documentation is used when building your Oasis.


## Backing up the Oasis

For detailed instructions on backing up the data on your Oasis we recommend reading the
[NOMAD documentation on administration](https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/administer.html#backups).

As part of this repository there is a bash script for running the mongodump in `scripts/backup-mongo.sh`.
1. Make sure you are in the top directory of this repository and that the `mongo` service (container `nomad_oasis_mongo`) is running.

2. Run the script:

    ```sh
    bash scripts/backup-mongo.sh
    ```

3. Check that a `nomad_oasis_v1` mongodump was created in `.volumes/mongo` and that the
dump was added to the logfile.

    ```sh
    ls .volumes/mongo
    cat .volumes/mongo/backup.log
    ```

4. (Optional) Add the script to the crontab to run for example every night at 2 am.
From the top directory of this repository, run:

    ```sh
    (crontab -l 2>/dev/null; echo "0 2 * * * bash $(realpath scripts/backup-mongo.sh)") | crontab -
    ```

    Finally, check that the cronjob was added:

    ```sh
    crontab -l
    ```

> [!CAUTION]
> This will only dump the NOMAD mongo data onto the server. It is still up to you
> to setup a proper backup of the dump in the `.volumes/mongo` directory as well as all
> the raw files in the `.volumes/fs` directory.

## Enabling NOMAD Actions

To enable NOMAD Actions, you need to decide whether you need a CPU worker, a GPU worker, or both, and then make the following changes:

1.  **Enable the required worker service(s) in `docker-compose.yaml`:**

    Uncomment the `cpu_worker` service, the `gpu_worker` service, or both in the `docker-compose.yaml` file depending on your needs.

2.  **Enable the corresponding build step(s) in the Docker publish workflow:**

    In the `.github/workflows/docker-publish.yml` file, uncomment the build step(s) corresponding to the worker(s) you enabled in the `docker-compose.yaml` file.

3.  **Adjust deployment resources:**

    If necessary, adjust the deployment resources (e.g., CPU, memory, replicas) for the enabled worker service(s) in the `docker-compose.yaml` file to match your server's capacity.

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
