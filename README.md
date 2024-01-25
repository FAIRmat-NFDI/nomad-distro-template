# nomad-example-image
An example repository for creating a nomad image with custom plugins.

## Deploying the image

To deploy this NOMAD Oasis image you should follow the instructions on [nomad-lab.eu/prod/v1/docs/oasis/install.html](https://nomad-lab.eu/prod/v1/docs/oasis/install.html) but replace the Docker image in `docker-compose.yaml` with `ghcr.io/hampusnasstrom/nomad-example-image:main` for the services `worker`, `app`, `north`, and `logtransfer`.

Remember to also update the `nomad.yaml` config file to include the new plugins.

### Quick-start

- Find a linux computer.
- Make sure you have [docker](https://docs.docker.com/engine/install/) installed.
Docker nowadays comes with `docker compose` build in. Prior, you needed to
install the stand alone [docker-compose](https://docs.docker.com/compose/install/).
- Download the modified configuration files [nomad-oasis.zip](https://github.com/hampusnasstrom/nomad-example-image/raw/main/nomad-oasis.zip) from this repository.
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

## Adding a plugin

To add a new plugin to the docker image you should add it to the [plugins.txt](https://github.com/hampusnasstrom/nomad-example-image/blob/main/plugins.txt) file.

Here you can put either plugins distributed to PyPI, e.g.
```
nomad-material-processing
```
or plugins in a git repository with either the commit hash
```
git+https://github.com/FAIRmat-NFDI/nomad-measurements.git@71b7e8c9bb376ce9e8610aba9a20be0b5bce6775
```
or with a tag
```
git+https://github.com/FAIRmat-NFDI/nomad-measurements.git@v0.0.4
```
To add a plugin in a subdirectory of a git repository you can use the `subdirectory` option, e.g.
```
git+https://github.com/FAIRmat-NFDI/AreaA-data_modeling_and_schemas.git@30fc90843428d1b36a1d222874803abae8b1cb42#subdirectory=PVD/PLD/jeremy_ikz/ikz_pld_plugin
```

Once the changes have been committed to the main branch, the new image will automatically be generated.