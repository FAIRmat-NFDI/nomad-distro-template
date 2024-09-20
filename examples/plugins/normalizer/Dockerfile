FROM gitlab-registry.mpcdf.mpg.de/nomad-lab/nomad-fair:latest

RUN pip install build

COPY \
    nomadnormalizerexample \
    tests \
    README.md \
    LICENSE \
    pyproject.toml \
    .

RUN python -m build --sdist

RUN pip install dist/nomad-normalizer-plugin-example-*.tar.gz
