#!/bin/sh

echo root | su -c '\
    set -e
    export PATH=$PATH:/usr/sbin
    for n in $(seq 30); do
        docker images | grep -q alpine && break
        sleep 10
    done
    docker run --rm quay.io/libpod/alpine:3.10.2 true
    for n in $(seq 30); do
        podman images | grep -q alpine && break
        sleep 10
    done
    podman run --rm quay.io/libpod/alpine:latest true
'
