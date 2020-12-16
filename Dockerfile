# Container image that runs your code
FROM alpine

ENV ART_IMG_WORKSPACE=/art-img
ENV PATH=$ART_IMG_WORKSPACE/bin:$PATH

# Copies your code file from your action repository to the filesystem path `/art-img/` of the container
# Trailing '/' is important
COPY * $ART_IMG_WORKSPACE/

RUN sh $ART_IMG_WORKSPACE/docker-setup-image.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/bin/bash", "-c"]