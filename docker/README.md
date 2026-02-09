# Deploying with Docker Compose

This folder contains the Docker Compose configuration for deploying a NOMAD Oasis distribution.

## Prerequisites

- [Docker](https://docs.docker.com/engine/install/) (with `docker compose` built in).
  Prior versions required the stand-alone [docker-compose](https://docs.docker.com/compose/install/).

## For a new Oasis

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

### Updating the image

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

## For an existing Oasis

If you already have an Oasis running, update the image in your `docker-compose.yaml` to
`ghcr.io/fairmat-nfdi/nomad-distro-template:main` for the services `worker`, `app`, `north`,
and `logtransfer`.

If you want to use the `nomad.yaml` from this repository, comment out the volume mount
in those services:

```yaml
volumes:
  # - ./configs/nomad.yaml:/app/nomad.yaml
```

Then pull and restart (steps 4 and 6 above).

## NOMAD Remote Tools Hub (NORTH)

The `north` (JupyterHub) container needs access to Docker. Replace the default group id `991`
in the `docker-compose.yaml` `north` section with your system's docker group id.

Find your docker group id:
```sh
id            # if you are a docker user
getent group | grep docker  # otherwise
```

The user id `1000` is the nomad user inside all containers.

## Configuring Worker Replicas and Resource Limits

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

## Backing up the Oasis

See the [NOMAD documentation on backups](https://nomad-lab.eu/prod/v1/staging/docs/howto/oasis/administer.html#backups).

A backup script is provided at `scripts/backup-mongo.sh` (in the repository root):

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

## Enabling NOMAD Actions

1. Uncomment the `cpu_worker` and/or `gpu_worker` service(s) in `docker-compose.yaml`.
2. Enable the corresponding build step(s) in `.github/workflows/docker-publish.yml`.
3. Adjust resource limits as needed.
