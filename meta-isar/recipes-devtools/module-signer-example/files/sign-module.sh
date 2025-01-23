#!/bin/sh
#
# Example signer script that generates detached signatures for modules
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

set -e

module=$1
signature=$2
hashfn=$3
certfile=$4

if [ -z "$module" ] || [ -z "$signature" ] || [ -z "$hashfn" ] || [ -z "$certfile" ] ; then
    exit 1
fi

echo "Signing module $module with hash function $hashfn and certificate $certfile"

openssl smime -sign -nocerts -noattr -binary \
    -in "$module" \
    -md "$hashfn" \
    -inkey /etc/sb-mok-keys/MOK/MOK.priv \
    -signer /etc/sb-mok-keys/MOK/MOK.der \
    -outform DER \
    -out "$signature"

echo "Verifying signature of module $module with hash function $hashfn and certificate $certfile"

openssl smime -verify \
    -in "$signature" \
    -md "$hashfn" \
    -content "$module" \
    -certfile /etc/sb-mok-keys/MOK/MOK.der \
    -noverify \
    -inform DER \
    -out /dev/null
