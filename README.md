![docker image](https://github.com/FAIRmat-NFDI/nomad-distribution-template/actions/workflows/docker-publish.yml/badge.svg)

> [!IMPORTANT] 
> The templated repository will run a GitHub action on creation which might take a few minutes.
> After the workflow finishes you should refresh the page and this message should disappear.
> If this message persists you might need to trigger the workflow manually by navigating to the
> "Actions" tab at the top, clicking "Template Repository Initialization" on the left side,
> and triggering it by clicking "Run workflow" under the "Run workflow" button on the right.

# NOMAD Oasis Distribution *Template*
This repository is a template for creating your own custom NOMAD Oasis distribution image.
Click [here](https://github.com/new?template_name=nomad-distribution-template&template_owner=FAIRmat-NFDI)
to use this template, or click the `Use this template` button in the upper right corner of
the main GitHub page for this template.

# Updating an Existing Distribution

In order to update an existing distribution with any potential changes in the template you can add a new `git remote` for the template and merge with that one while allowing for unrelated histories:

```
git remote add template https://github.com/FAIRmat-NFDI/nomad-distribution-template
git fetch template
git merge template/main --allow-unrelated-histories
```

Most likely this will result in some merge conflicts which will need to be resolved. At the very least the `Dockerfile` and GitHub workflows should be taken from "theirs":

```
git checkout --theirs Dockerfile
git checkout --theirs .github/workflows/docker-publish.yml
```

## Migrating to building the full docker image (Version 2)
When moving from the first to the second version of the distribution image you can choose to keep your `docker-compose.yaml`:

```
git checkout --ours docker-compose.yaml
```

You can choose whether to keep your `README.md` but we recommend updating it as it contains the updated instructions for how to use the distribution repository:
```
git checkout --theirs README.md
```

The plugins are now listed in the `pyproject.toml` instead of the `plugins.txt` and can be added there with `uv` and the `plugins.txt` removed:

```
uv add --optional plugins -r plugins.txt --no-sync
rm plugins.txt
```

The `nomad.yaml` is now moved to the `configs` directory, please copy over your existing `nomad.yaml` there:

```
mv nomad.yaml configs/nomad.yaml
```

Finally, the new recommendation is to either `git clone` the distribution repository or to `curl` the whole repository so the `nomad-oasis.zip` can also be removed:

```
rm nomad-oasis.zip
```

## Commit the Changes and Run the Workflows

Once the merge conflict is resolved you should add the changes and commit them

```
git add -A
git commit -m "Updated to new distribution version"
```

Ideally all workflows should be triggered automatically but you might need to run the initialization one manually by navigating to the "Actions" tab at the top, clicking "Template Repository Initialization" on the left side, and triggering it by clicking "Run workflow" under the "Run workflow" button on the right.