#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd "$parent_path"

cp -rf ../nomad.yaml ../nomad-oasis/configs/nomad.yaml
zip -r ../nomad-oasis.zip ../nomad-oasis