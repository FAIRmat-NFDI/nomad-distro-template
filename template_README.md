![docker image](https://github.com/GITHUB_REPOSITORY/actions/workflows/docker-publish.yml/badge.svg)

# GITHUB_REPOSITORY_OWNER's NOMAD Oasis Distribution

This is the NOMAD Oasis distribution of GITHUB_REPOSITORY_OWNER. 
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

## Deploying the distribution

Below are instructions for how to deploy this NOMAD Oasis distribution
[for a new Oasis](#for-a-new-oasis) and [for an existing Oasis](#for-an-existing-oasis)

### For a new Oasis

1. Make sure you have [docker](https://docs.docker.com/engine/install/) installed.
Docker nowadays comes with `docker compose` built in. Prior, you needed to
install the stand-alone [docker-compose](https://docs.docker.com/compose/install/).
2. Get the `nomad-oasis.zip` archive from your distribution repository using for example curl
```sh
curl -L -o nomad-oasis.zip "https://github.com/GITHUB_REPOSITORY/raw/main/nomad-oasis.zip"
```
3. Unzip the `nomad-oasis.zip` file and enter the extracted directory
```sh
unzip nomad-oasis.zip
cd nomad-oasis
```
4. _On Linux only,_ recursively change the owner of the `.volumes` directory to the nomad user (1000) 
```sh
sudo chown -R 1000 .volumes
```
5. Pull the images specified in the `docker-compose.yaml` (retrieved from the `nomad-oasis.zip`).
Note that the image needs to be public or you need to provide a PAT (see "Important" note above).
```sh
docker compose pull
```
6. And run it with docker compose in detached (--detach or -d) mode 
```sh
docker compose up -d
```
7. Optionally you can now test that NOMAD is running with
```
curl localhost/nomad-oasis/alive
```
8. Finally, open [http://localhost/nomad-oasis](http://localhost/nomad-oasis) in your browser to start using your new NOMAD Oasis.

Whenever you update your image you need to shut down NOMAD using
```sh
docker compose down
```
and then repeat steps 5. and 6. above.

#### NOMAD Remote Tools Hub (NORTH)
To run NORTH (the NOMAD Remote Tools Hub), the `hub` container needs to run docker and
the container has to be run under the docker group. You need to replace the default group
id `991` in the `docker-compose.yaml`'s `hub` section with your systems docker group id.
Run `id` if you are a docker user, or `getent group | grep docker` to find your
systems docker gid. The user id 1000 is used as the nomad user inside all containers.

You can find more details on setting up and maintaining an Oasis in the NOMAD docs here:
[nomad-lab.eu/prod/v1/docs/oasis/install.html](https://nomad-lab.eu/prod/v1/docs/oasis/install.html)

### For an existing Oasis

If you already have an Oasis running you only need to change the image being pulled in
your `docker-compose.yaml` with `ghcr.io/GITHUB_REPOSITORY:main` for the services
`worker`, `app`, `north`, and `logtransfer`.

If you want to use the `nomad.yaml` from this repository you also need to comment out
the inclusion of the `nomad.yaml` under the volumes key of those services in the
`docker-compose.yaml`.

```yaml
    volumes:
      # - ./configs/nomad.yaml:/app/nomad.yaml
```

To run the new image you can follow steps 5. and 6. [above](#for-a-new-oasis).

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

## FAQ/Trouble shooting

 *I get an* `Error response from daemon: Head "https://ghcr.io/v2/GITHUB_REPOSITORY/manifests/main": unauthorized`
 *when trying to pull my docker image.*
 
 Most likely you have not made the package public or provided a personal access token (PAT).
 You can read how to make your package public in the GitHub docs [here](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)
 or how to configure a PAT (if you want to keep the distribution private) in the GitHub
 docs [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic).
