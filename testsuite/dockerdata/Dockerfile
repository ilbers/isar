FROM ghcr.io/siemens/kas/kas-isar:<version>

ARG TARGETPLATFORM
ARG DEBIAN_FRONTEND=noninteractive

# Isar testsuite dependencies
RUN sudo pip3 --proxy=$https_proxy install avocado-framework==100.1 && \
    sudo apt-get update && \
    sudo apt-get install -y -f --no-install-recommends qemu-system ovmf && \
    sudo apt-get clean && \
    sudo rm -rf $(pip3 cache dir) /var/lib/apt/lists/* /tmp/* /var/tmp/*
