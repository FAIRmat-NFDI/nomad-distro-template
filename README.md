![docker image](https://github.com/FAIRmat-NFDI/nomad-distribution-template/actions/workflows/docker-publish.yml/badge.svg)

> [!IMPORTANT] 
> The templated repository will run a GitHub action on creation which might take a few momements.
> After the workflow finishes you should refresh the page and this message should disappear.

# NOMAD Oasis Distribution *Template*
This repository is a template for creating your own custom NOMAD Oasis distribution image.
Click [here](https://github.com/new?template_name=nomad-distribution-template&template_owner=FAIRmat-NFDI)
to use this template, or click the `Use this template` button in the upper right corner of
the main GitHub page for this template.

## Deploying the image

To deploy this NOMAD Oasis image you should follow the instructions on [nomad-lab.eu/prod/v1/docs/oasis/install.html](https://nomad-lab.eu/prod/v1/docs/oasis/install.html) but replace the Docker image in `docker-compose.yaml` with `ghcr.io/FAIRmat-NFDI/nomad-distribution-template:main` for the services `worker`, `app`, `north`, and `logtransfer`.

Remember to also update the `nomad.yaml` config file to include the new plugins.

### Quick-start

- Find a linux computer.
- Make sure you have [docker](https://docs.docker.com/engine/install/) installed.
Docker nowadays comes with `docker compose` build in. Prior, you needed to
install the stand alone [docker-compose](https://docs.docker.com/compose/install/).
- Download the modified configuration files [nomad-oasis.zip](nomad-oasis_files/nomad-oasis.zip) from this repository.
- Run the following commands (skip `chown` on MacOS and Windows computers)


```sh
unzip nomad-oasis.zip
cd nomad-oasis
sudo chown -R 1000 .volumes
docker compose pull
docker compose up -d
curl localhost/nomad-oasis/alive
```

- Open [http://localhost/nomad-oasis](http://localhost/nomad-oasis) in your browser.

To run NORTH (the NOMAD Remote Tools Hub), the `hub` container needs to run docker and
the container has to be run under the docker group. You need to replace the default group
id `991` in the `docker-compose.yaml`'s `hub` section with your systems docker group id.
Run `id` if you are a docker user, or `getent group | grep docker` to find our your
systems docker gid. The user id 1000 is used as the nomad user inside all containers.
