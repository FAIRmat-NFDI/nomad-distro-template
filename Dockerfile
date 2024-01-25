FROM gitlab-registry.mpcdf.mpg.de/nomad-lab/nomad-fair:develop
USER root
RUN apt-get update
RUN apt-get -y install git
COPY plugins.txt plugins.txt
RUN pip install -r plugins.txt
USER nomad