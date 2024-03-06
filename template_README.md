![docker image](https://github.com/GITHUB_REPOSITORY/actions/workflows/docker-publish.yml/badge.svg)

# GITHUB_REPOSITORY_OWNER's NOMAD Oasis Distribution

This is the NOMAD Oasis distribution of GITHUB_REPOSITORY_OWNER. 
Below are instructions for how to [deploy this image](#deploying-the-image) and how to
customize it through [adding plugins](#adding-a-plugin).

> [!IMPORTANT] 
> Depending on the settings of the owner of this repository, the distributed image might
> be private and require authentication to pull.
> If you are the owner you should make sure that your organization settings allow public
> packages and after that set this package public.
> You can read more about this in the GitHub docs [here](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility).

> [!TIP]
> In order for you others to find and learn from your distribution we in FAIRmat would
> greatly appreciate it if you would add the topic `nomad-distribution` by clicking the
> ⚙️ next to "About" on the main GitHub page for this repository.

## Deploying the image

To deploy this NOMAD Oasis image you should follow the instructions on
[nomad-lab.eu/prod/v1/docs/oasis/install.html](https://nomad-lab.eu/prod/v1/docs/oasis/install.html)
but replace the Docker image in `docker-compose.yaml` with `ghcr.io/GITHUB_REPOSITORY:main` 
for the services `worker`, `app`, `north`, and `logtransfer`.

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

## Adding a plugin

To add a new plugin to the docker image you should add it to the [plugins.txt](plugins.txt) file.

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

If the plugin is new, you also need to add it under `plugins` in the [nomad.yaml](nomad.yaml)
config file that will be included in the image.
For example, if you have added a schema plugin `nomad_material_processing` you should add 
the following:

```yaml
plugins:
  options:
    schemas/nomad_material_processing:
      python_package: nomad_material_processing
```

Once the changes have been committed to the main branch, the new image will automatically 
be generated.