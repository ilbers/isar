ARG KAS_VERSION=0

FROM ghcr.io/siemens/kas/kas-isar:${KAS_VERSION}

ARG TARGETPLATFORM
ARG DEBIAN_FRONTEND=noninteractive

# Isar testsuite dependencies
RUN sudo pip3 --proxy=$https_proxy install --break-system-packages avocado-framework==103.0 && \
    sudo apt-get update && \
    sudo apt-get install -y -f --no-install-recommends qemu-system ovmf && \
    sudo apt-get install -y -f --no-install-recommends python3-apt && \
    sudo apt-get clean && \
    sudo rm -rf $(pip3 cache dir) /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY testsuite/dockerdata/test-container-entrypoint /

ENTRYPOINT ["/test-container-entrypoint"]
