FROM gitlab-registry.mpcdf.mpg.de/nomad-lab/nomad-fair:develop@sha256:f2276472027fc80e7c359f1df0f40b3fc9b9e473c8ddb89e012c023b7887fe3a
USER root
RUN apt-get update
RUN apt-get -y install git
USER nomad
COPY plugins.txt plugins.txt
RUN pip install -r plugins.txt
