#!/bin/bash

set -e

working_dir=$(pwd)
project_dir=$(dirname $(dirname $(dirname $(realpath $0))))

cd $project_dir

# Copy nomad.yaml to the configs directory
cp -rf nomad.yaml nomad-oasis_files/nomad-oasis/configs/nomad.yaml

# Replace the default docker image path with the actual docker image path
if [[ -n $1 ]]; then
  sed -i "s|hampusnasstrom/nomad-example-image|$1|g" nomad-oasis_files/nomad-oasis/docker-compose.yaml
  sed -i "s|hampusnasstrom/nomad-example-image|$1|g" README.md
fi

# Compress the nomad-oasis directory
zip -r nomad-oasis_files/nomad-oasis.zip nomad-oasis_files/nomad-oasis